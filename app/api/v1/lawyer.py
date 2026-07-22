import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, selectinload
from typing import List

from app.core.database import get_db_ops
from app.api.v1.auth import get_current_user
from app.models.user import User
from app.models.report import Report
from app.models.report_message import ReportMessage
from app.schemas.report import ReportResponse, ReportListResponse
from app.schemas.lawyer import LawyerReviewAction, ReportMessageCreate, ReportMessageResponse
from app.services.report_service import ReportService, utcnow

router = APIRouter()

@router.get("/reports", response_model=ReportListResponse, summary="Get reports assigned to the current lawyer")
def get_lawyer_reports(
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    """Retrieve list of reports submitted by citizens linked to this lawyer."""
    if current_user.role != "lawyer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only lawyers can access client reports."
        )

    # Filter reports where report.lawyerId == current_user.userId
    query = db.query(Report).options(selectinload(Report.attachments)).filter(Report.lawyerId == current_user.userId)
    total = query.count()
    reports = query.order_by(Report.createdAt.desc()).offset(skip).limit(limit).all()

    from app.services.blob_service import BlobStorageService
    blob_service = BlobStorageService()
    report_responses = []

    for r in reports:
        attachment_responses = []
        for att in r.attachments:
            download_url = blob_service.generate_download_url(att.blobStorageUri)
            attachment_responses.append({
                "attachmentId": att.attachmentId,
                "reportId": att.reportId,
                "blobStorageUri": att.blobStorageUri,
                "downloadUrl": download_url,
                "mimeType": att.mimeType,
                "fileType": att.fileType,
                "fileSizeBytes": att.fileSizeBytes,
                "createdAt": utcnow()
            })

        report_responses.append(
            ReportResponse(
                reportId=r.reportId,
                title=r.title,
                descriptionText=r.descriptionText,
                categoryId=r.categoryId,
                status=r.status,
                location=r.locationRaw,
                latitude=r.latitude,
                longitude=r.longitude,
                aiConfidence=r.aiConfidence,
                createdAt=r.createdAt,
                updatedAt=r.updatedAt,
                userId=r.userId,
                transcribedVoiceText=r.transcribedVoiceText,
                officerNote=r.officerNote,
                lawyerId=r.lawyerId,
                lawyerSignature=r.lawyerSignature,
                lawyerFeedback=r.lawyerFeedback,
                isUrgentEscalation=r.isUrgentEscalation,
                attachments=attachment_responses
            )
        )

    return ReportListResponse(
        reports=report_responses,
        total=total,
        page=(skip // limit) + 1 if limit > 0 else 1,
        pageSize=limit,
        totalPages=(total + limit - 1) // limit if limit > 0 else 1
    )

@router.post("/reports/{report_id}/action", response_model=ReportResponse, summary="Lawyer review action")
def lawyer_report_action(
    report_id: str,
    payload: LawyerReviewAction,
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    """Approve & Forward, Return with Feedback, or Urgently Escalate a report."""
    if current_user.role != "lawyer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only lawyers can review and take action on client reports."
        )

    report = db.query(Report).filter(Report.reportId == report_id, Report.lawyerId == current_user.userId).first()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found or not assigned to this lawyer."
        )

    action = payload.action.strip().lower()

    if action == "approve":
        report.status = "Submitted"
        report.lawyerSignature = payload.lawyerSignature or current_user.digitalSignatureUrl or f"SIGNED BY ADVOCATE (Syndicate ID: {current_user.syndicateId})"
        report.lawyerFeedback = None
        report.isUrgentEscalation = False
    elif action == "return":
        report.status = "ReturnedToCitizen"
        report.lawyerFeedback = payload.lawyerFeedback or "Requires further clarification and evidence."
        report.lawyerSignature = None
    elif action == "escalate":
        report.status = "Submitted"
        report.isUrgentEscalation = True
        report.lawyerSignature = payload.lawyerSignature or current_user.digitalSignatureUrl or f"URGENT ESCALATION BY ADVOCATE (Syndicate ID: {current_user.syndicateId})"
        report.lawyerFeedback = payload.lawyerFeedback or "URGENT LEGAL RISK: Immediate Law Enforcement Action Required."
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid action. Must be 'approve', 'return', or 'escalate'."
        )

    report.updatedAt = utcnow()
    db.commit()
    db.refresh(report)

    return ReportService.get_report(db, report_id)

@router.get("/reports/{report_id}/messages", response_model=List[ReportMessageResponse], summary="Get private chat logs")
def get_report_messages(
    report_id: str,
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    """Retrieve chat history between client and lawyer for a specific report."""
    report = db.query(Report).filter(Report.reportId == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    # Authorize: user must be the reporting citizen or the assigned lawyer
    if current_user.userId not in [report.userId, report.lawyerId] and current_user.role not in ["officer", "admin"]:
        raise HTTPException(status_code=403, detail="Not authorized to view these messages")

    messages = db.query(ReportMessage).filter(ReportMessage.reportId == report_id).order_by(ReportMessage.createdAt.asc()).all()
    return messages

@router.post("/reports/{report_id}/messages", response_model=ReportMessageResponse, summary="Send a private message")
def create_report_message(
    report_id: str,
    payload: ReportMessageCreate,
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    """Send a chat message to client/lawyer regarding an incident."""
    report = db.query(Report).filter(Report.reportId == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    # Authorize: user must be the reporting citizen or the assigned lawyer
    if current_user.userId not in [report.userId, report.lawyerId]:
        raise HTTPException(status_code=403, detail="Not authorized to post messages")

    sender_role = "lawyer" if current_user.role == "lawyer" else "citizen"

    message = ReportMessage(
        messageId=f"msg-{uuid.uuid4()}",
        reportId=report_id,
        senderId=current_user.userId,
        senderRole=sender_role,
        messageText=payload.messageText,
        createdAt=utcnow()
    )

    db.add(message)
    db.commit()
    db.refresh(message)
    return message
