from sqlmodel import SQLModel, Field
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy import String
from datetime import datetime
from typing import Optional
import uuid

class ChatMessage(SQLModel, table=True):
    __tablename__ = "chat_messages"

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        sa_column=Column(UUID(as_uuid=True), primary_key=True, unique=True, nullable=False)
    )
    event_id: uuid.UUID = Field(
        sa_column=Column(UUID(as_uuid=True), nullable=False, index=True)
    )
    user_id: uuid.UUID = Field(
        sa_column=Column(UUID(as_uuid=True), nullable=False, index=True)
    )
    username: str = Field(
        sa_column=Column(String(50), nullable=False)
    )
    email: Optional[str] = Field(
        default=None,
        sa_column=Column(String(100), nullable=True, index=True)
    )
    message: str = Field(
        sa_column=Column(String(1000), nullable=False)
    )
    timestamp: datetime = Field(
        default_factory=datetime.now(),
        sa_column=Column(TIMESTAMP(timezone=True), nullable=False, index=True)
    )
