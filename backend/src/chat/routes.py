from src.chat.models import ChatMessage
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from datetime import datetime, timezone
from src.db.main import get_session


from src.chat.websocket_manager import WebSocketManager
from src.auth.dependencies import AccessTokenFromWSBearer
from src.events.models import Event, EventResponse
from sqlalchemy import or_
from fastapi import WebSocket, WebSocketDisconnect, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from sqlalchemy import or_
import uuid
import json
from src.notifications.models import Notification
from src.notifications.fcm import send_fcm_push

from src.chat.models import ChatMessage
from src.chat.websocket_manager import WebSocketManager
from src.db.main import get_session
from src.auth.dependencies import AccessTokenFromWSBearer
from src.events.models import Event, EventResponse
from src.auth.models import User

manager = WebSocketManager()

chat_router = APIRouter()

@chat_router.websocket("/ws/{event_id}")
async def chat_ws(
    websocket: WebSocket,
    event_id: str,
    user: dict = Depends(AccessTokenFromWSBearer()),
    session: AsyncSession = Depends(get_session)
):
    try:
        event_uuid = uuid.UUID(event_id)
    except ValueError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    user_uuid = uuid.UUID(user["sub"])   

    
    user_obj = await session.get(User, user_uuid)
    if not user_obj:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    
    stmt = select(Event).where(
        Event.id == event_uuid,
        or_(
            Event.creator_id == user_uuid,
            Event.id.in_(
                select(EventResponse.event_id).where(EventResponse.user_id == user_uuid)
            )
        )
    )
    result = await session.exec(stmt)
    if not result.first():
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    
    await manager.connect(event_id, websocket)

     
    result = await session.exec(
        select(ChatMessage)
        .where(ChatMessage.event_id == event_uuid)
        .order_by(ChatMessage.timestamp.asc())
    )
    past_messages = result.all()
    for msg in past_messages:
        await websocket.send_text(json.dumps({
            "username": msg.username,
            "email": msg.email,
            "message": msg.message,
            "timestamp": msg.timestamp.isoformat()
        }))

    try:
        while True:
             
            text = await websocket.receive_text()
            text = text.strip()

            if not text:
                continue

            
            chat_msg = ChatMessage(
                event_id=event_uuid,
                user_id=user_uuid,
                username=user_obj.username,
                email=user_obj.email,
                message=text,
                timestamp=datetime.now(datetime.timezone.utc),
            )
            session.add(chat_msg)
            await session.commit()

             
            await manager.broadcast(event_id, json.dumps({
                "username": chat_msg.username,
                "email": chat_msg.email,
                "message": chat_msg.message,
                "timestamp": chat_msg.timestamp.isoformat()
            }))

            # --- Notification and FCM push for chat message ---
            # Find all event attendees except sender
            attendees_stmt = select(EventResponse.user_id).where(
                EventResponse.event_id == event_uuid,
                EventResponse.user_id != user_uuid
            )
            attendees_result = await session.exec(attendees_stmt)
            attendee_ids = attendees_result.all()
            # Also notify event creator if not sender
            event_obj = await session.get(Event, event_uuid)
            if event_obj and event_obj.creator_id != user_uuid:
                attendee_ids.append(event_obj.creator_id)
            # Remove duplicates
            attendee_ids = list(set(attendee_ids))
            for recipient_id in attendee_ids:
                recipient = await session.get(User, recipient_id)
                if recipient:
                    # Create notification in DB
                    notification = Notification(
                        user_id=recipient.uid,
                        event_id=str(event_uuid),
                        event_title=event_obj.title if event_obj else '',
                        message=f"New message from {user_obj.username}: {text}",
                        is_read=False,
                        type="chat_message"
                    )
                    session.add(notification)
                    await session.commit()
                    # Send FCM push if token exists
                    if recipient.fcm_token:
                        try:
                            send_fcm_push(
                                token=recipient.fcm_token,
                                title="New Chat Message",
                                body=f"{user_obj.username}: {text}",
                                data={"type": "chat_message", "event_id": str(event_uuid)}
                            )
                        except Exception as e:
                            print(f"FCM push failed: {e}")

    except WebSocketDisconnect:
        manager.disconnect(event_id, websocket)

    except Exception as e:
        manager.disconnect(event_id, websocket)
        print(f"[WebSocket Error] {e}")
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR)

 

@chat_router.get("/{event_id}/messages")
async def get_chat_messages(event_id: str, session: AsyncSession = Depends(get_session)):
    result = await session.exec(
        select(ChatMessage)
        .where(ChatMessage.event_id == event_id)
        .order_by(ChatMessage.timestamp.asc())
    )
    messages = result.all()
    return [
        {
            "username": m.username,
            "email": m.email,   
            "message": m.message,
            "timestamp": m.timestamp.isoformat()
        } for m in messages
    ]
