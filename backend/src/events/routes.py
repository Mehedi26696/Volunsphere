from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlmodel import select
from typing import List
from datetime import datetime, timezone
from uuid import UUID 
import uuid

from src.db.main import get_session
from src.auth.dependencies import AccessTokenBearer
from src.events.models import Event,EventResponse
from src.auth.models import User
from src.events.schemas import EventCreate, EventRead, EventResponseUpdate, EventResponseRead
from supabase import create_client
from src.config import Config


events_router = APIRouter()

@events_router.post("/create", response_model=EventRead)
async def create_event(
    event: EventCreate,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    
    
    user_id = UUID(token_data.get("sub"))

    db_event = Event(
        title=event.title,
        description=event.description,
        location=event.location,
        start_datetime=event.start_datetime,
        end_datetime=event.end_datetime,
        duration_minutes=int((event.end_datetime - event.start_datetime).total_seconds() / 60),
        latitude=event.latitude,
        longitude=event.longitude,
        image_urls=event.image_urls or [],
        creator_id=user_id,
        created_at=datetime.now(),
        updated_at=datetime.now()
    )

    session.add(db_event)
    await session.commit()
    await session.refresh(db_event)
    return db_event

@events_router.get("/my", response_model=List[EventRead])
async def get_my_events(
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session),
):
    user_id_str = token_data.get("sub")
    if not user_id_str:
        raise HTTPException(status_code=401, detail="Unauthorized")
    user_id = UUID(user_id_str)

    statement = select(Event).where(Event.creator_id == user_id).order_by(Event.start_datetime)
    result = await session.exec(statement)
    events = result.all()
    return events

@events_router.get("/all", response_model=List[EventRead])
async def get_all_events(session: AsyncSession = Depends(get_session)):
    statement = select(Event).order_by(Event.start_datetime)
    result = await session.exec(statement)
    events = result.all()
    return events

@events_router.get("/{event_id}", response_model=EventRead)
async def get_event_by_id(event_id: UUID, session: AsyncSession = Depends(get_session)):
    event = await session.get(Event, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event

@events_router.delete("/{event_id}")
async def delete_event(event_id: UUID, token_data: dict = Depends(AccessTokenBearer()), session: AsyncSession = Depends(get_session)):
    user_id = UUID(token_data["sub"])
    event = await session.get(Event, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.creator_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    await session.delete(event)
    await session.commit()
    return {"message": "Event deleted"}

from fastapi import Body

@events_router.put("/{event_id}", response_model=EventRead)
async def update_event(
    event_id: UUID,
    event_update: EventCreate = Body(...),
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    event = await session.get(Event, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.creator_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    # Update fields
    event.title = event_update.title
    event.description = event_update.description
    event.location = event_update.location
    event.start_datetime = event_update.start_datetime
    event.end_datetime = event_update.end_datetime
    event.duration_minutes = int((event.end_datetime - event.start_datetime).total_seconds() / 60)
    if event.duration_minutes < 0:
        raise HTTPException(status_code=400, detail="End time must be after start time")
    
    event.image_urls = event_update.image_urls or []
    event.latitude = event_update.latitude
    event.longitude = event_update.longitude
    event.updated_at = datetime.now()

    session.add(event)
    await session.commit()
    await session.refresh(event)
    return event



@events_router.post("/{event_id}/join", status_code=201)
async def join_event(
    event_id: uuid.UUID,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session),
):
    user_id = uuid.UUID(token_data["sub"])

     
    stmt = select(EventResponse).where(EventResponse.event_id == event_id, EventResponse.user_id == user_id)
    result = await session.exec(stmt)
    if result.first():
        raise HTTPException(status_code=400, detail="Already joined")

     
    event_stmt = select(Event).where(Event.id == event_id)
    event_result = await session.exec(event_stmt)
    event = event_result.first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

     
    now = datetime.now(timezone.utc)
    if now > event.end_datetime:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot join event after it has ended"
        )

    # All good, create RSVP
    rsvp = EventResponse(event_id=event_id, user_id=user_id)
    session.add(rsvp)
    await session.commit()
    return {"message": "Joined event"}

@events_router.post("/{event_id}/leave", status_code=200)
async def leave_event(
    event_id: uuid.UUID,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session),
):
    user_id = uuid.UUID(token_data["sub"])

    stmt = select(EventResponse).where(EventResponse.event_id == event_id, EventResponse.user_id == user_id)
    result = await session.exec(stmt)
    rsvp = result.first()
    if not rsvp:
        raise HTTPException(status_code=400, detail="Not joined")

    await session.delete(rsvp)
    await session.commit()
    return {"message": "Left event"}

@events_router.get("/{event_id}/attendees/count", response_model=int)
async def get_attendees_count(
    event_id: uuid.UUID,
    session: AsyncSession = Depends(get_session)
):
    stmt = select(EventResponse).where(EventResponse.event_id == event_id)
    result = await session.exec(stmt)
    count = len(result.all())
    return count

@events_router.get("/{event_id}/attendees")
async def get_attendees(event_id: UUID, session: AsyncSession = Depends(get_session)):
     
    stmt = (
        select(User, EventResponse)
        .join(EventResponse, User.uid == EventResponse.user_id)
        .where(EventResponse.event_id == event_id)
    )
    result = await session.exec(stmt)
    rows = result.all()   

    attendees = []
    for user, response in rows:
        attendees.append({
            "id": user.uid,
            "username": user.username,
            "email": user.email,
            "profile_image_url": user.profile_image_url,
            "phone": user.phone,
            "rating": response.rating or 0,
            "work_time_hours": response.work_time_hours or 0.0,
        })
    return attendees



supabase = create_client(Config.SUPABASE_URL, Config.SUPABASE_KEY)
@events_router.post("/upload-event-images/")
async def upload_event_images(event_id: str, files: List[UploadFile] = File(...)):
    if len(files) > 3:
        raise HTTPException(status_code=400, detail="You can only upload up to 3 images.")

    urls = []

    for file in files:
        file_ext = file.filename.split('.')[-1]
        unique_filename = f"{event_id}/{uuid.uuid4()}.{file_ext}"
        content = await file.read()

        res = supabase.storage.from_("event-images").upload(unique_filename, content)
        if getattr(res, "error", None):
            raise HTTPException(status_code=500, detail="Failed to upload image.")

        public_url = supabase.storage.from_("event-images").get_public_url(unique_filename)
        urls.append(public_url)

    return {"image_urls": urls}


@events_router.patch("/{event_id}/responses/{user_id}")
async def update_event_response(
    event_id: uuid.UUID,
    user_id: uuid.UUID,
    payload: EventResponseUpdate,
    session: AsyncSession = Depends(get_session),
    token_data: dict = Depends(AccessTokenBearer()),
):
    
    event_stmt = select(Event).where(Event.id == event_id)
    event_result = await session.exec(event_stmt)
    event = event_result.first()

    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

     
    if token_data["sub"] != str(user_id) and token_data["sub"] != str(event.creator_id):
        raise HTTPException(status_code=403, detail="Not authorized to update this response")

    
    stmt = select(EventResponse).where(
        EventResponse.event_id == event_id,
        EventResponse.user_id == user_id
    )
    result = await session.exec(stmt)
    response = result.first()

    if not response:
        raise HTTPException(status_code=404, detail="Response not found")

     
    response.work_time_hours = payload.work_time_hours
    response.rating = payload.rating
    session.add(response)
    await session.commit()
    await session.refresh(response)
    return {"message": "Response updated successfully"}


 