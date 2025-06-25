

from fastapi import FastAPI

 
from contextlib import asynccontextmanager
from src.db.main import init_db
from src.auth.routes import auth_router
from src.events.routes import events_router
from src.users.routes import user_router
from src.chat.routes import chat_router
from src.community.routes import community_router
from src.leaderboard.routes import leaderboard_router


@asynccontextmanager
async def lifespan(app: FastAPI):

    print(f"Server is starting...")
    await init_db()
    yield
    print(f"Server has been stopped.")
     

version = "v1"

app = FastAPI(
    title = "Volunsphere",
    description ="A place to connect with volunteer communities and find oppurtunities",
    version=version,
    lifespan=lifespan,
)

app.include_router(auth_router,prefix = "/api/{version}/auth",tags=["auth"])
app.include_router(events_router, prefix="/api/{version}/events", tags=["events"])
app.include_router(user_router, prefix="/api/{version}/users", tags=["users"])
app.include_router(chat_router, prefix="/api/{version}/chat", tags=["chat"])
app.include_router(community_router, prefix="/api/{version}/community", tags=["community"])
app.include_router(leaderboard_router, prefix="/api/{version}/leaderboard", tags=["leaderboard"])

