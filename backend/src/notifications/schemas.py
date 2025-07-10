from pydantic import BaseModel
from datetime import datetime
from typing import Optional
import uuid

class NotificationCreate(BaseModel):
    user_id: uuid.UUID
    event_id: Optional[str] = None
    event_title: Optional[str] = None
    message: str
    type: str = "new_message"

class NotificationRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    event_id: Optional[str] = None
    event_title: Optional[str] = None
    message: str
    timestamp: datetime
    is_read: bool
    type: str

    class Config:
        from_attributes = True
