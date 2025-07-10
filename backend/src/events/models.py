from sqlmodel import SQLModel, Field
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy import Float, Integer, UniqueConstraint, CheckConstraint
from datetime import datetime
from typing import Optional
import uuid
from typing import List
from sqlalchemy.dialects.postgresql import JSON



class Event(SQLModel, table=True):
    __tablename__ = "events"

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        sa_column=Column(UUID(as_uuid=True), primary_key=True, unique=True, nullable=False)
    )
    title: str
    description: Optional[str] = None
    location: Optional[str] = None


    
    start_datetime: datetime = Field(
        sa_column=Column(TIMESTAMP(timezone=True), nullable=False)
    )
    end_datetime: datetime = Field(
        sa_column=Column(TIMESTAMP(timezone=True), nullable=False)
    )

     
    duration_minutes: int = Field(
        default=0,
        sa_column=Column(Integer, nullable=False)
    )

    latitude: Optional[float] = Field(default=None, nullable=True)
    longitude: Optional[float] = Field(default=None, nullable=True)
    image_urls: List[str] = Field(default_factory=list, sa_column=Column(JSON))

    creator_id: uuid.UUID = Field(
        sa_column=Column(UUID(as_uuid=True), nullable=False)
    )

    created_at: datetime = Field(
        default_factory=datetime.now,
        sa_column=Column(TIMESTAMP(timezone=True), nullable=False)
    )
    updated_at: datetime = Field(
        default_factory=datetime.now,
        sa_column=Column(TIMESTAMP(timezone=True), nullable=False)
    )

    def __repr__(self):
        return f"<Event {self.title} - {self.start_datetime.isoformat()} to {self.end_datetime.isoformat()} ({self.duration_minutes} min)>"




class EventResponse(SQLModel, table=True):
    __tablename__ = "event_responses"

    __table_args__ = (
        UniqueConstraint('event_id', 'user_id', name='unique_event_user'),
        CheckConstraint('rating >= 0 AND rating <= 5', name='rating_range_check'),
        CheckConstraint('work_time_hours >= 0', name='work_time_non_negative'),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, sa_column=Column(UUID(as_uuid=True), primary_key=True))
    event_id: uuid.UUID = Field(sa_column=Column(UUID(as_uuid=True), nullable=False))
    user_id: uuid.UUID = Field(sa_column=Column(UUID(as_uuid=True), nullable=False))

    work_time_hours: float = Field(default=0.0, sa_column=Column(Float, nullable=False, default=0.0))
    rating: int = Field(default=0, sa_column=Column(Integer, nullable=False, default=0))