from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class LawyerReviewAction(BaseModel):
    action: str = Field(..., description="Action: approve, return, escalate")
    lawyerSignature: Optional[str] = Field(None, description="Signature text (Required if action is approve or escalate)")
    lawyerFeedback: Optional[str] = Field(None, description="Feedback text (Required if action is return)")

class ReportMessageCreate(BaseModel):
    messageText: str = Field(..., min_length=1, description="Content of the chat message")

class ReportMessageResponse(BaseModel):
    messageId: str
    reportId: str
    senderId: str
    senderRole: str
    messageText: str
    createdAt: datetime

    class Config:
        from_attributes = True
