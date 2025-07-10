from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

from contextlib import asynccontextmanager
from src.db.main import init_db
from src.db.redis import redis_client
from src.auth.routes import auth_router
from src.events.routes import events_router
from src.users.routes import user_router
from src.chat.routes import chat_router
from src.community.routes import community_router
from src.leaderboard.routes import leaderboard_router
from src.chatbot.routes import chatbot_router
from src.notifications.routes import notification_router
from src.auth.fcm_routes import fcm_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🚀 Server is starting...")
    try:
        await init_db()
        print(f"✅ Database initialized successfully")
    except Exception as e:
        print(f"⚠️ Database initialization warning: {e}")
        # Continue anyway, tables might already exist
    
    # Test Redis connection
    try:
        await redis_client.ping()
        print(f"✅ Redis connected successfully")
    except Exception as e:
        print(f"⚠️ Redis connection warning: {e}")
        # Continue anyway, Redis is optional
    
    yield
    
    # Cleanup
    try:
        await redis_client.close()
        print(f"🔌 Redis disconnected")
    except Exception as e:
        print(f"⚠️ Redis disconnect warning: {e}")
    
    print(f"🛑 Server has been stopped.")

version = "v1"

app = FastAPI(
    title="Volunsphere",
    description="A place to connect with volunteer communities and find opportunities",
    version=version,
    lifespan=lifespan,
)

# Add CORS middleware - Allow all origins since frontend will be hosted separately
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for external frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "Volunsphere API"}

@app.get("/")
async def root():
    return {"message": "Welcome to Volunsphere API", "version": version, "docs": "/docs"}

# Fix router prefixes with f-strings
app.include_router(auth_router, prefix=f"/api/{version}/auth", tags=["auth"])
app.include_router(events_router, prefix=f"/api/{version}/events", tags=["events"])
app.include_router(user_router, prefix=f"/api/{version}/users", tags=["users"])
app.include_router(chat_router, prefix=f"/api/{version}/chat", tags=["chat"])
app.include_router(community_router, prefix=f"/api/{version}/community", tags=["community"])
app.include_router(leaderboard_router, prefix=f"/api/{version}/leaderboard", tags=["leaderboard"])
app.include_router(chatbot_router, prefix=f"/api/{version}/chatbot", tags=["chatbot"])
app.include_router(notification_router, prefix=f"/api/{version}/notifications", tags=["notifications"])
app.include_router(fcm_router, prefix=f"/api/{version}/fcm", tags=["fcm"])

