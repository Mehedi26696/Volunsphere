from sqlmodel import SQLModel, Field, Column
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy import Boolean
from datetime import datetime
import uuid

class Notification(SQLModel, table=True):
    __tablename__ = "notifications"

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        sa_column=Column(UUID(as_uuid=True), primary_key=True, unique=True, nullable=False)
    )
    user_id: uuid.UUID = Field(sa_column=Column(UUID(as_uuid=True), nullable=False))
    event_id: str = Field(nullable=True)
    event_title: str = Field(nullable=True)
    message: str
    timestamp: datetime = Field(default_factory=datetime.now, sa_column=Column(TIMESTAMP(timezone=True), nullable=False))
    is_read: bool = Field(default=False, sa_column=Column(Boolean, nullable=False))
    type: str = Field(default="new_message")
