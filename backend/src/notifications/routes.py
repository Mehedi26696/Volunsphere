from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.db.main import get_session
from src.notifications.models import Notification
from src.notifications.schemas import NotificationCreate, NotificationRead
from src.auth.models import User
from uuid import UUID
from datetime import datetime
from src.notifications.fcm import send_fcm_push

notification_router = APIRouter()

@notification_router.post("/", response_model=list[NotificationRead])
async def create_notification(notification: NotificationCreate, session: AsyncSession = Depends(get_session)):
    created_notifications = []
    for user_id in notification.user_ids:
        db_notification = Notification(
            user_id=user_id,
            event_id=notification.event_id,
            event_title=notification.event_title,
            message=notification.message,
            type=notification.type,
            timestamp=datetime.now(),
            is_read=False
        )
        session.add(db_notification)
        await session.commit()
        await session.refresh(db_notification)
        created_notifications.append(db_notification)

        # Send FCM push notification
        user_result = await session.execute(select(User).where(User.uid == user_id))
        user = user_result.scalar_one_or_none()
        if user and user.fcm_token:
            try:
                send_fcm_push(
                    token=user.fcm_token,
                    title=notification.event_title or "Volunsphere Notification",
                    body=notification.message,
                    data={"type": notification.type, "event_id": notification.event_id or ""}
                )
            except Exception as e:
                print(f"FCM push failed: {e}")

    return created_notifications

@notification_router.get("/{user_id}", response_model=list[NotificationRead])
async def get_notifications(user_id: UUID, session: AsyncSession = Depends(get_session)):
    result = await session.execute(
        select(Notification).where(
            (Notification.user_id == user_id) & (Notification.is_read == False)
        )
    )
    notifications = result.scalars().all()
    return notifications

@notification_router.post("/{notification_id}/read")
async def mark_as_read(notification_id: UUID, session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Notification).where(Notification.id == notification_id))
    notification = result.scalar_one_or_none()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    notification.is_read = True
    await session.commit()
    return {"status": "success"}
