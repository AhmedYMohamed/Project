from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import Optional

from app.core.database import get_db_ops
from app.api.v1.auth import get_current_user
from app.models.user import User
from app.schemas.report import ReportListResponse
from app.services.report_service import ReportService

router = APIRouter()

@router.get(
    "/reports/nearby",
    response_model=ReportListResponse,
    summary="Get reports near the officer's active service area"
)
def get_nearby_reports(
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    radius_deg: float = Query(0.1, description="Radius in degrees (approx 10km)")
):
    """
    Finds the active OfficerServiceArea for the current user and returns reports within the specified radius.
    """
    if current_user.role.lower() != "officer":
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only officers can access nearby reports."
         )
         
    return ReportService.get_nearby_reports(
        db=db,
        user_id=current_user.userId,
        skip=skip,
        limit=limit,
        radius_deg=radius_deg
    )
