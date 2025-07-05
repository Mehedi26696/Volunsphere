from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DATABASE_URL : str
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
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

Config = Settings()