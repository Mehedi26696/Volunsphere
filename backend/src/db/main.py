
from sqlmodel import create_engine,SQLModel

from sqlalchemy.ext.asyncio import AsyncEngine

from src.config import Config

from sqlmodel.ext.asyncio.session import AsyncSession

from sqlalchemy.orm import sessionmaker




async_engine = AsyncEngine(
    create_engine(
        Config.DATABASE_URL,
        echo=True 
    )
)


async def init_db() -> None:
    async with async_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

         

async def get_session() -> AsyncSession:
    async_session = sessionmaker(
        bind=async_engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    async with async_session() as session:
        yield session