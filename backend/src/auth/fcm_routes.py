from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.db.main import get_session
from src.auth.models import User
from uuid import UUID

fcm_router = APIRouter()

@fcm_router.post("/users/{user_id}/fcm-token")
async def update_fcm_token(user_id: UUID, token: str, session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(User).where(User.uid == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.fcm_token = token
    await session.commit()
    return {"status": "success"}
