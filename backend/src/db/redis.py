import redis.asyncio as redis
from src.config import Config

JTI_EXPIRY = 3600  
OTP_EXPIRY = 300   

# Redis client instance - use the connection params from config
redis_client = redis.Redis(**Config.redis_connection_params)

 

async def add_jti_to_blocklist(jti: str) -> None:
     
    await redis_client.set(name=jti, value="", ex=JTI_EXPIRY)

async def is_jti_blocked(jti: str) -> bool:
     
    value = await redis_client.get(jti)
    return value is not None

 

async def set_otp(email: str, otp: str) -> None:
     
    key = f"otp:{email}"
    await redis_client.set(name=key, value=otp, ex=OTP_EXPIRY)

async def get_otp(email: str) -> str:
     
    key = f"otp:{email}"
    return await redis_client.get(key)

async def delete_otp(email: str) -> None:
     
    key = f"otp:{email}"
    await redis_client.delete(key)

