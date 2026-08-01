from fastapi import APIRouter, UploadFile, File, HTTPException, status, Depends
import os
import shutil
import uuid
import logging
import requests
import json
import whisper
from typing import Optional
from app.api.v1.auth import get_current_user
from app.models.user import User

logger = logging.getLogger(__name__)
router = APIRouter()

# ==========================================
# Munsit & Ollama Configuration
# ==========================================
MUNSIT_API_KEY = os.getenv(
    "MUNSIT_API_KEY",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlfaWQiOiI2YTkwZWIxMS1hMmIzLTRlNTUtYWUwYi0wZjViYWQwODkxYzYiLCJpYXQiOjE3ODMyNzY0MjAsImV4cCI6MjA5ODYzNjQyMH0.NOatq3sehs7YmlifK_0n0LXNup48u04gWNaJ7quRO3g"
)
MUNSIT_URL = os.getenv("MUNSIT_URL", "https://api.cntxt.tools/audio/transcribe")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")

# Whisper Local Model Singleton (Fallback)
_model = None

def get_whisper_model():
    global _model
    if _model is None:
        logger.info("Loading local Whisper model for fallback...")
        try:
            _model = whisper.load_model("turbo")
            logger.info("Local Whisper 'turbo' model loaded successfully.")
        except Exception as e:
            logger.warning(f"Could not load Whisper 'turbo' model: {e}. Trying 'base'...")
            _model = whisper.load_model("base")
    return _model


def _transcribe_with_munsit(file_path: str) -> Optional[str]:
    """
    Transcribes audio via Munsit API with high accuracy for Arabic dialects.
    Returns the transcription text if successful, or None if API fails.
    """
    try:
        headers = {"Authorization": f"Bearer {MUNSIT_API_KEY}"}
        file_base_name = os.path.basename(file_path)
        ext = os.path.splitext(file_base_name)[1].lower()
        
        mime_types = {
            ".mp3": "audio/mpeg",
            ".wav": "audio/wav",
            ".m4a": "audio/m4a",
            ".ogg": "audio/ogg",
            ".flac": "audio/flac",
            ".aac": "audio/aac",
        }
        mime_type = mime_types.get(ext, "audio/mpeg")

        logger.info(f"Connecting to Munsit API for audio transcription: {file_base_name} ({mime_type})")

        with open(file_path, "rb") as audio_file:
            files_data = {"file": (file_base_name, audio_file, mime_type)}
            data = {"model": "munsit"}
            
            response = requests.post(
                MUNSIT_URL,
                headers=headers,
                files=files_data,
                data=data,
                timeout=25
            )
            
            if response.status_code == 200:
                res_json = response.json()
                raw_text = res_json.get("data", {}).get("transcription", "")
                if not raw_text and isinstance(res_json.get("data"), str):
                    raw_text = res_json.get("data")
                if not raw_text:
                    raw_text = res_json.get("transcription", "") or res_json.get("text", "")

                raw_text = str(raw_text).strip()
                if raw_text:
                    logger.info("✓ Munsit API transcription successful!")
                    return raw_text
                    
            logger.warning(f"⚠ Munsit API returned non-200 status [{response.status_code}]: {response.text[:200]}")
            return None
    except Exception as e:
        logger.warning(f"⚠ Munsit API connection failed or timed out: {e}")
        return None


def _transcribe_with_whisper(file_path: str) -> str:
    """
    Fallback transcription using local OpenAI Whisper model.
    """
    logger.info("Executing local Whisper fallback transcription...")
    model = get_whisper_model()
    my_prompt = "يا باشا، إحنا هنا بنتكلم مصري عادي، وبنقول كلام زي 'إزيك' و'عملت إيه' و'شغل الموتور'. ركز مع اللهجة المصرية."
    
    result = model.transcribe(
        file_path,
        language="ar",
        initial_prompt=my_prompt
    )
    return result.get("text", "").strip()


def _enhance_with_qwen(raw_text: str) -> str:
    """
    Optional enhancement via local Qwen/Ollama for minor dialect & spell corrections.
    If Ollama is offline or fails, returns raw_text safely without error.
    """
    if not raw_text or len(raw_text) < 3:
        return raw_text
        
    prompt = f"""أنت مساعد ذكي في غرفة عمليات وزارة الداخلية.
المهمة: قم بتصحيح الأخطاء الإملائية أو النطقية في البلاغ التالي بشكل طفيف جداً وواضح بدون تغيير المعنى الجنائي أو المكان.
أرجع فقط النص المصحح بدون أي مقدمات أو ملاحظات أو علامات إضافية.

النص المفرغ:
{raw_text}
"""
    payload = {
        "model": "qwen2.5:7b",
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": 0.1}
    }
    
    try:
        response = requests.post(OLLAMA_URL, json=payload, timeout=5)
        if response.status_code == 200:
            corrected = response.json().get("response", "").strip()
            if corrected.startswith("```"):
                lines = corrected.splitlines()
                corrected = "\n".join([l for l in lines if not l.startswith("```")]).strip()
            if corrected and len(corrected) > 2:
                return corrected
    except Exception:
        pass
        
    return raw_text


@router.post("/transcribe", status_code=status.HTTP_200_OK)
async def transcribe_voice(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Receives an audio file, transcribes it using high-accuracy Munsit API 
    (with automatic fallback to local Whisper), and returns the transcribed text.
    """
    logger.info(f"Received voice transcription request from user {current_user.userId}: {file.filename}")
    
    temp_dir = "temp_audio"
    os.makedirs(temp_dir, exist_ok=True)
    
    file_ext = os.path.splitext(file.filename)[1] or ".m4a"
    temp_filename = f"{uuid.uuid4()}{file_ext}"
    temp_file_path = os.path.join(temp_dir, temp_filename)
    
    try:
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 1. Primary: Try Munsit API
        transcribed_text = _transcribe_with_munsit(temp_file_path)
        
        # 2. Secondary: Fallback to local Whisper if Munsit failed
        if not transcribed_text:
            logger.info("Munsit API unavailable or returned empty result. Switching to Whisper fallback.")
            transcribed_text = _transcribe_with_whisper(temp_file_path)
            
        # 3. Optional enhancement via Qwen if available
        final_text = _enhance_with_qwen(transcribed_text)
        
        logger.info(f"Final transcription completed successfully ({len(final_text)} chars).")
        return {"text": final_text}

    except Exception as e:
        logger.error(f"Error during voice transcription: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred during voice transcription: {str(e)}"
        )
    finally:
        # Guarantee temp file cleanup to prevent disk bloat
        if os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception as clean_err:
                logger.warning(f"Could not remove temp file {temp_file_path}: {clean_err}")
