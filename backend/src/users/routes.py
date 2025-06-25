from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import Optional

from src.db.main import get_session
from src.auth.dependencies import AccessTokenBearer
import uuid

from src.events.models import EventResponse
from src.events.models import Event
from src.events.models import EventResponse
from src.auth.models import User
from uuid import UUID
 

user_router = APIRouter()

@user_router.get("/stats")
async def get_user_stats(
    session: AsyncSession = Depends(get_session),
    token_data: dict = Depends(AccessTokenBearer())
):
    user_id = token_data["sub"]

 
    stmt_joined = select(func.count(EventResponse.event_id)).where(EventResponse.user_id == uuid.UUID(user_id))
    result_joined = await session.execute(stmt_joined)
    events_joined = result_joined.scalar_one() or 0

    stmt_hours = select(func.coalesce(func.sum(EventResponse.work_time_hours), 0)).where(EventResponse.user_id == uuid.UUID(user_id))
    result_hours = await session.execute(stmt_hours)
    hours_volunteered = result_hours.scalar_one() or 0.0

    stmt_rating = select(func.avg(EventResponse.rating)).where(EventResponse.user_id == uuid.UUID(user_id))
    result_rating = await session.execute(stmt_rating)
    average_rating: Optional[float] = result_rating.scalar_one()
    if average_rating is None:
        average_rating = 0.0

    return {
        "events_joined": events_joined,
        "hours_volunteered": float(hours_volunteered),
        "average_rating": round(float(average_rating), 2),
    }


@user_router.get("/certificate_data")
async def get_certificate_data(
    session: AsyncSession = Depends(get_session),
    token_data: dict = Depends(AccessTokenBearer())
):
    user_id = uuid.UUID(token_data["sub"])

    stmt_joined = select(func.count(EventResponse.event_id)).where(EventResponse.user_id == user_id)
    result_joined = await session.execute(stmt_joined)
    events_joined = result_joined.scalar_one() or 0

    stmt_hours = select(func.coalesce(func.sum(EventResponse.work_time_hours), 0)).where(EventResponse.user_id == user_id)
    result_hours = await session.execute(stmt_hours)
    hours_volunteered = result_hours.scalar_one() or 0.0

    stmt_rating = select(func.avg(EventResponse.rating)).where(EventResponse.user_id == user_id)
    result_rating = await session.execute(stmt_rating)
    average_rating: Optional[float] = result_rating.scalar_one() or 0.0

    stmt_events = (
        select(Event.title)
        .join(EventResponse, EventResponse.event_id == Event.id)
        .where(EventResponse.user_id == user_id)
        .distinct()
    )
    result_titles = await session.execute(stmt_events)
    joined_event_titles = [row[0] for row in result_titles.all()]

    return {
        "events_joined": events_joined,
        "hours_volunteered": float(hours_volunteered),
        "average_rating": round(float(average_rating or 0.0), 2),
        "joined_event_titles": joined_event_titles,
    }


@user_router.get("/{user_id}")
async def get_user_by_id(
    user_id: UUID,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session),
):
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": str(user.uid),
        "username": user.username,
        "email": user.email,
        "profile_image_url": user.profile_image_url,
        "phone": user.phone,
    }


@user_router.get("/certificate_data/{user_id}")
async def get_certificate_data_for_user(
    user_id: UUID,
    session: AsyncSession = Depends(get_session)
):
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    stmt = select(EventResponse).where(EventResponse.user_id == user_id)
    result = await session.execute(stmt)
    responses = result.scalars().all()

    total_hours = sum(r.work_time_hours or 0 for r in responses)
    ratings = [r.rating for r in responses if r.rating is not None]
    average_rating = round(sum(ratings) / len(ratings), 2) if ratings else 0.0

    joined_event_ids = [r.event_id for r in responses]
    stmt_events = select(Event).where(Event.id.in_(joined_event_ids))
    result_events = await session.execute(stmt_events)
    event_titles = [e.title for e in result_events.scalars().all()]

    return {
        "events_joined": len(joined_event_ids),
        "hours_volunteered": total_hours,
        "average_rating": average_rating,
        "joined_event_titles": event_titles
    }
