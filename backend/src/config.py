from pydantic_settings import BaseSettings, SettingsConfigDict
import os

class Settings(BaseSettings):
    DATABASE_URL : str
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    
    # Redis Configuration - Railway provides REDIS_URL
    REDIS_URL: str = "redis://localhost:6379"  # Default for local
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    
    GMAIL_USER: str
    GMAIL_PASSWORD: str
    SUPABASE_URL: str
    SUPABASE_KEY: str
    GROQ_API_KEY: str
    GEMINI_API_KEY: str
    ENVIRONMENT: str = "development"

    model_config = SettingsConfigDict(
        env_file = ".env",
        extra="ignore"
    )

    @property
    def async_database_url(self) -> str:
        """Convert DATABASE_URL to use asyncpg driver"""
        url = self.DATABASE_URL
        if url.startswith("postgresql://"):
            return url.replace("postgresql://", "postgresql+asyncpg://", 1)
        elif url.startswith("postgres://"):
            return url.replace("postgres://", "postgresql+asyncpg://", 1)
        return url

    @property 
    def sync_database_url(self) -> str:
        """Convert DATABASE_URL to use psycopg2 driver for alembic"""
        url = self.DATABASE_URL
        if url.startswith("postgresql+asyncpg://"):
            return url.replace("postgresql+asyncpg://", "postgresql://", 1)
        elif url.startswith("postgres://"):
            return url.replace("postgres://", "postgresql://", 1)
        return url

    @property
    def redis_connection_params(self) -> dict:
        """Get Redis connection parameters"""
        if self.REDIS_URL and self.REDIS_URL.startswith("redis://"):
            # Parse Redis URL for Railway
            import urllib.parse
            parsed = urllib.parse.urlparse(self.REDIS_URL)
            return {
                "host": parsed.hostname or "localhost",
                "port": parsed.port or 6379,
                "password": parsed.password,
                "decode_responses": True
            }
        else:
            # Use individual host/port for local development
            return {
                "host": self.REDIS_HOST,
                "port": self.REDIS_PORT,
                "decode_responses": True
            }

Config = Settings()