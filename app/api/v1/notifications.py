from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db_ops
from app.api.v1.auth import get_current_user
from app.models.user import User
from app.models.notification import Notification
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

class NotificationResponse(BaseModel):
    notificationId: str
    userId: str
    title: str
    body: str
    type: str | None = None
    reportId: str | None = None
    isRead: bool
    createdAt: datetime

    class Config:
        from_attributes = True

@router.get("/", response_model=List[NotificationResponse], summary="Get all notifications for current user")
def get_user_notifications(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    notifications = (
        db.query(Notification)
        .filter(Notification.userId == current_user.userId)
        .order_by(Notification.createdAt.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return notifications

@router.get("/unread-count", summary="Get unread notifications count")
def get_unread_count(
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    count = (
        db.query(Notification)
        .filter(Notification.userId == current_user.userId, Notification.isRead == False)
        .count()
    )
    return {"unreadCount": count}

@router.put("/{notification_id}/read", summary="Mark notification as read")
def mark_notification_as_read(
    notification_id: str,
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    notif = (
        db.query(Notification)
        .filter(Notification.notificationId == notification_id, Notification.userId == current_user.userId)
        .first()
    )
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")

    notif.isRead = True
    db.commit()
    return {"message": "Marked as read"}

@router.put("/read-all", summary="Mark all notifications as read")
def mark_all_as_read(
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    db.query(Notification).filter(
        Notification.userId == current_user.userId,
        Notification.isRead == False
    ).update({"isRead": True}, synchronize_session=False)
    db.commit()
    return {"message": "All marked as read"}
