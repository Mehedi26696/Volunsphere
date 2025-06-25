from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field, confloat, conint
import uuid
from typing import List

class EventCreate(BaseModel):
    title: str
    description: Optional[str] = None
    location: Optional[str] = None
    start_datetime: datetime
    end_datetime: datetime
    image_urls: Optional[List[str]] = []
    latitude: Optional[float] = Field(default=None, nullable=True)
    longitude: Optional[float] = Field(default=None, nullable=True)

class EventRead(BaseModel):
    id: uuid.UUID
    title: str
    description: Optional[str] = None
    location: Optional[str] = None
    start_datetime: datetime
    end_datetime: datetime
    image_urls: Optional[List[str]] = []
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    creator_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True


class EventResponseUpdate(BaseModel):
    work_time_hours: Optional[float] = Field(default=None, ge=0)
    rating: Optional[int] = Field(default=None, ge=0, le=5)

class EventResponseRead(BaseModel):
    id: uuid.UUID
    event_id: uuid.UUID
    user_id: uuid.UUID
    work_time_hours: float
    rating: int

    class Config:
        orm_mode = True