import os
import sys
import logging
from typing import Optional, List
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, Field

from app.api.v1.auth import get_current_user
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter()

# Resolve path to RAG_pipeline directory
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
RAG_DIR = os.path.join(BASE_DIR, "RAG_pipeline")
if RAG_DIR not in sys.path:
    sys.path.insert(0, RAG_DIR)

_rag_pipeline = None

def get_rag_instance():
    """
    Lazy singleton initialization of RAG DataPipeline with correct relative CWD context.
    """
    global _rag_pipeline
    if _rag_pipeline is None:
        logger.info(f"Initializing RAG DataPipeline from {RAG_DIR}...")
        orig_cwd = os.getcwd()
        try:
            os.chdir(RAG_DIR)
            from Data_Indexing.pipeline_DataLoad import DataPipeline
            law_books_path = os.path.join(RAG_DIR, "All_Law_Books")
            _rag_pipeline = DataPipeline(pdf_path=law_books_path, verbose=False)
            logger.info("✓ RAG DataPipeline initialized successfully.")
        except Exception as e:
            logger.error(f"Failed to initialize RAG DataPipeline: {e}", exc_info=True)
            raise e
        finally:
            os.chdir(orig_cwd)
    return _rag_pipeline


class ChatRequest(BaseModel):
    query: str = Field(..., min_length=1, description="The legal question asked by the citizen")

class ChatResponse(BaseModel):
    answer: str
    status: str = "success"


@router.post("/chat", response_model=ChatResponse, status_code=status.HTTP_200_OK)
async def legal_chatbot_query(
    request: ChatRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Legal Chatbot Endpoint - CITIZEN ROLE ONLY.
    Queries Egyptian law books using RAG pipeline and returns legal advisory context.
    """
    # Strict role verification: Citizen only
    user_role = getattr(current_user, 'role', '').lower()
    if user_role != 'citizen':
        logger.warning(f"Unauthorized Chatbot access attempt by user {current_user.userId} with role '{user_role}'")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="المستشار القانوني متاح فقط لحسابات المواطنين (The Legal Chatbot is only available for Citizens)."
        )

    logger.info(f"Chatbot query from Citizen {current_user.userId}: '{request.query[:50]}...'")

    orig_cwd = os.getcwd()
    try:
        os.chdir(RAG_DIR)
        pipeline = get_rag_instance()
        answer = pipeline.llm_response(request.query)
        return ChatResponse(answer=answer, status="success")
    except Exception as e:
        logger.error(f"Error executing Chatbot query: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"حدث خطأ أثناء معالجة الاستشارة القانونية: {str(e)}"
        )
    finally:
        os.chdir(orig_cwd)
