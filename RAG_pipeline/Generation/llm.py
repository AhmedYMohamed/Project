import os
import requests
import json
import logging
from app.core.config import get_settings

logger = logging.getLogger(__name__)

def ask_llm(prompt: str) -> str:
    settings = get_settings()
    
    endpoint = settings.AZURE_OPENAI_ENDPOINT
    api_key = settings.AZURE_OPENAI_KEY
    deployment = settings.AZURE_OPENAI_DEPLOYMENT
    
    # Fallback to system environment variables
    if not endpoint:
        endpoint = os.getenv("AZURE_OPENAI_ENDPOINT", "https://uaenorth.api.cognitive.microsoft.com/")
    if not api_key:
        api_key = os.getenv("AZURE_OPENAI_KEY")
    if not deployment:
        deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-5-mini")
        
    if not api_key:
        logger.error("Azure OpenAI API Key is missing.")
        return "❌ خطأ: لم يتم تهيئة مفتاح الوصول لـ Azure OpenAI."

    base_url = endpoint.rstrip("/")
    url = f"{base_url}/openai/deployments/{deployment}/chat/completions?api-version=2024-02-15-preview"
    
    headers = {
        "Content-Type": "application/json",
        "api-key": api_key
    }
    
    payload = {
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "max_completion_tokens": 4000
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        data = response.json()
        return data["choices"][0]["message"]["content"].strip()
    except Exception as e:
        logger.error(f"Error calling Azure OpenAI: {e}", exc_info=True)
        # Try standard python urllib as absolute fallback
        try:
            import urllib.request
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers=headers,
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                res_data = json.loads(resp.read().decode("utf-8"))
                return res_data["choices"][0]["message"]["content"].strip()
        except Exception as fallback_err:
            logger.error(f"Fallback urllib request also failed: {fallback_err}")
            return f"❌ خطأ أثناء الاتصال بـ Azure OpenAI: {str(e)}"