from fastapi import APIRouter, Depends, HTTPException
from sqlmodel.ext.asyncio.session import AsyncSession
from src.db.main import get_session
from src.auth.models import User
from src.events.models import EventResponse
from sqlalchemy import func, select
from fastapi import Query

leaderboard_router = APIRouter()

@leaderboard_router.get("/", response_model=list[dict])
async def get_leaderboard(
    sort_by: str = Query("overall", regex="^(rating|hours|events|overall)$"),
    session: AsyncSession = Depends(get_session)
):
    events_joined = func.count(EventResponse.id)
    avg_rating = func.coalesce(func.avg(EventResponse.rating), 0)
    total_hours = func.coalesce(func.sum(EventResponse.work_time_hours), 0)
    overall_score = (avg_rating * 2) + total_hours + events_joined

    stmt = (
        select(
            User.uid,
            User.username,
            User.profile_image_url,
            User.email,
            User.phone,
            events_joined.label("events_joined"),
            avg_rating.label("avg_rating"),
            total_hours.label("total_hours"),
            overall_score.label("overall_score")
        )
        .join(EventResponse, EventResponse.user_id == User.uid, isouter=True)
        .group_by(User.uid)
    )

    if sort_by == "rating":
        stmt = stmt.order_by(avg_rating.desc())
    elif sort_by == "hours":
        stmt = stmt.order_by(total_hours.desc())
    elif sort_by == "events":
        stmt = stmt.order_by(events_joined.desc())
    else:
        stmt = stmt.order_by(overall_score.desc())

    stmt = stmt.limit(50)

    result = await session.exec(stmt)
    rows = result.all()

    return [
        {
            "uid": row.uid,
            "username": row.username,
            "profile_image_url": row.profile_image_url,
            "email": row.email,
            "phone": row.phone,
            "events_joined": row.events_joined,
            "avg_rating": round(row.avg_rating, 2),
            "total_hours": round(row.total_hours, 2),
            "overall_score": round(row.overall_score, 2),
        }
        for row in rows
    ]