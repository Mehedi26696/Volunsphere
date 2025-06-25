from passlib.context import CryptContext
from datetime import timedelta, datetime
from src.config import Config
import jwt
import uuid
import logging
from datetime import datetime, timezone
import smtplib
from email.message import EmailMessage
import os
import smtplib
from email.mime.text import MIMEText
import random
from src.config import Config
from src.db.redis import redis_client



datetime.now(timezone.utc)



password_context = CryptContext(
    schemes=["bcrypt"]
)

ACCESS_TOKEN_EXPIRY = 120

def generate_hash_password(password: str) -> str:
     

    hash = password_context.hash(password)
    if not hash:
        raise ValueError("Password hashing failed")
    return  hash

def verify_password(plain_password: str, hashed_password: str) -> bool:
    

    return password_context.verify(plain_password, hashed_password)

def create_access_token(user_data: dict, expiry: timedelta = None, refresh: bool = False):
     
    payload = {}

    payload["sub"] = str(user_data["uid"])  # ✅ Set user ID as subject
    payload["email"] = user_data["email"]   # Optional, good for quick access
    payload["exp"] = datetime.now(timezone.utc) + (expiry or timedelta(seconds=ACCESS_TOKEN_EXPIRY))
    payload["jti"] = str(uuid.uuid4())
    payload["refresh"] = refresh
    payload["ws"] = True
    payload["id"] = str(user_data["uid"])

    token = jwt.encode(
        payload=payload,
        key=Config.JWT_SECRET_KEY,
        algorithm=Config.JWT_ALGORITHM
    )

    return token


def decode_token(token: str) -> dict:
     
    try:
        token_data = jwt.decode(
            jwt=token,
            key=Config.JWT_SECRET_KEY,
            algorithms=[Config.JWT_ALGORITHM]
       )
        return token_data
    except jwt.PyJWTError as e:
        logging.exception(e)
        return None



OTP_EXPIRY = 300  # 5 minutes
def generate_otp(length=6):
    return ''.join(str(random.randint(0, 9)) for _ in range(length))

async def store_otp(email: str, otp: str):
    await redis_client.set(name=f"otp:{email}", value=otp, ex=OTP_EXPIRY)

async def get_stored_otp(email: str):
    return await redis_client.get(f"otp:{email}")

async def delete_otp(email: str):
    await redis_client.delete(f"otp:{email}")

from email.mime.text import MIMEText
import smtplib

def send_otp_email(recipient_email: str, otp: str):
    subject = "VolunSphere - Password Reset OTP"

    body = f"""
Dear User,

We received a request to reset your password for your VolunSphere account.

Your One-Time Password (OTP) is:

🔒 {otp}

Please enter this OTP in the app to proceed with resetting your password.

⚠️ This OTP is valid for a 5 minutes. If you do not enter it within this time, you will need to request a new OTP.

If you did not request a password reset, please ignore this email or contact support.

Thank you,  
The VolunSphere Team
"""

    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = Config.GMAIL_USER
    msg['To'] = recipient_email

    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
        server.login(Config.GMAIL_USER, Config.GMAIL_PASSWORD)
        server.send_message(msg)
