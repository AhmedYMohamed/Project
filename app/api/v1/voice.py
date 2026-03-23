from fastapi import APIRouter, UploadFile, File, HTTPException, status, Depends
import os
import shutil
import uuid
import logging
import whisper
from app.api.v1.auth import get_current_user
from app.models.user import User

logger = logging.getLogger(__name__)
router = APIRouter()

# Load Whisper model (Global singleton)
# Note: This might take time on first request or application startup
_model = None

def get_whisper_model():
    global _model
    if _model is None:
        logger.info("Loading Whisper 'turbo' model...")
        # You can change "turbo" to "base" or "small" for faster processing on slower machines
        _model = whisper.load_model("turbo")
        logger.info("Whisper model loaded successfully.")
    return _model

@router.post("/transcribe", status_code=status.HTTP_200_OK)
async def transcribe_voice(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Receives an audio file, transcribes it using OpenAI Whisper, 
    and returns the transcribed text.
    """
    logger.info(f"Received transcription request for file: {file.filename}")
    
    # 1. Save file temporarily
    temp_dir = "temp_audio"
    os.makedirs(temp_dir, exist_ok=True)
    
    file_ext = os.path.splitext(file.filename)[1] or ".m4a"
    temp_filename = f"{uuid.uuid4()}{file_ext}"
    temp_file_path = os.path.join(temp_dir, temp_filename)
    
    try:
        # Write to temporary file
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        logger.info(f"File saved to {temp_file_path}. Transcribing...")
        
        # 2. Use Whisper to transcribe
        model = get_whisper_model()
        
        # Egyptian Arabic prompt as specified in the user's script
        my_prompt = "يا باشا، إحنا هنا بنتكلم مصري عادي، وبنقول كلام زي 'إزيك' و'عملت إيه' و'شغل الموتور'. ركز مع اللهجة المصرية."
        
        result = model.transcribe(
            temp_file_path,
            language="ar",
            initial_prompt=my_prompt
        )
        
        transcribed_text = result.get("text", "").strip()
        
        # 3. Clean up
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
            
        logger.info("Transcription completed successfully.")
        return {"text": transcribed_text}
    
    except Exception as e:
        logger.error(f"Error during transcription: {str(e)}")
        if os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except:
                pass
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred during transcription: {str(e)}"
        )
