from fastapi import APIRouter, Depends,status
from src.auth.schemas import UserCreateModel, UserModel , UserLoginModel , UserUpdateModel, PasswordChangeRequest , ForgotPasswordRequest, VerifyOTPRequest, ResetPasswordRequest

from .service import UserService
from src.db.main import get_session
from sqlmodel.ext.asyncio.session import AsyncSession
from fastapi.exceptions import HTTPException
from .utils import create_access_token, decode_token, verify_password, generate_hash_password ,generate_otp,store_otp,get_stored_otp,delete_otp,send_otp_email
from datetime import timedelta , datetime, timezone
from fastapi.responses import JSONResponse
from .dependencies import RefreshTokenBearer,AccessTokenBearer
from src.db.redis import is_jti_blocked, add_jti_to_blocklist
from src.auth.models import User
import uuid
from uuid import UUID 
from sqlmodel import select 
import os 
import jwt 
from pydantic import EmailStr
import random
from src.config import Config
from supabase import create_client
from fastapi import UploadFile, File



auth_router = APIRouter()

user_service = UserService()

REFRESH_TOKEN_EXPIRY = 2  # days

# Bearer token authentication 


@auth_router.post(
        '/signup',
        response_model=UserModel,
        status_code=status.HTTP_201_CREATED
                
)
async def create_user_account( user_data: UserCreateModel , session: AsyncSession = Depends(get_session)):
     
    email = user_data.email
    user_exists = await user_service.user_exists(email, session)
    if user_exists:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User with this email already exists."
        )
    
    username = user_data.username
    user_exists_by_username = await user_service.user_exists_by_username(username, session)
    if user_exists_by_username:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User with this username already exists."
        )
    
    new_user = await user_service.create_user(user_data, session)
    if not new_user:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user account."
        )
    return new_user


@auth_router.post('/login')
async def login_user(login_data: UserLoginModel, session: AsyncSession = Depends(get_session)):

    email = login_data.email
    password = login_data.password

    user = await user_service.get_user_by_email(email, session)
    
    if user is not None:
        
        password_valid = verify_password(password, user.password_hash)
        if password_valid:
            user_data = {
                "uid": str(user.uid),
                "email": user.email
                 
            }
            access_token = create_access_token(user_data)
            refresh_token = create_access_token(user_data, refresh=True, expiry=timedelta(days=REFRESH_TOKEN_EXPIRY))
            
            return JSONResponse(
                status_code=status.HTTP_200_OK,
                content={
                    "message": "Login successful",
                    "access_token": access_token,
                    "refresh_token": refresh_token,
                    "user": user_data
                }
            )
        
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid email or password"
    )
     
    
@auth_router.get('/refresh_token')
async def  get_new_access_token( 
    token_details: dict = Depends(RefreshTokenBearer()),
    session: AsyncSession = Depends(get_session)):
     
    expiry_timestamp = token_details.get('exp')

    if datetime.fromtimestamp(expiry_timestamp) > datetime.now():
        new_access_token = create_access_token(
            token_details, 
            expiry=timedelta(minutes=15)  # Set a new expiry for the access token
        )
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "message": "Access token refreshed successfully",
                "access_token": new_access_token
            }
        )
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Refresh token has expired"
    )

@auth_router.get('/logout')
async def revoke_token(
    token_details: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
     
    jti = token_details.get('jti')
    
    if jti:
        await add_jti_to_blocklist(jti)
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"message": "Logout successful, token revoked"}
        )
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Invalid token"
    )

@auth_router.get("/profile")
async def get_user_profile(
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = token_data.get("sub")
    user_uuid = uuid.UUID(user_id)   

    statement = select(User).where(User.uid == UUID(user_id))
    result = await session.exec(statement)
    user = result.first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "uid": str(user.uid),
        "username": user.username,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "city": user.city,
        "country": user.country,
        "phone": user.phone,
        "profile_image_url": user.profile_image_url,
    }


@auth_router.put("/profile", response_model=UserModel)
async def update_user_profile(
    user_update: UserUpdateModel,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = token_data.get("sub")
    user_uuid = uuid.UUID(user_id)

    statement = select(User).where(User.uid == user_uuid)
    result = await session.exec(statement)
    user = result.first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    

    for key, value in user_update.model_dump().items():
        if value is not None:
            setattr(user, key, value)

    await session.commit()
    await session.refresh(user)

    return user

@auth_router.put("/change-password")
async def change_password(
    password_change: PasswordChangeRequest,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = token_data.get("sub")
    user_uuid = uuid.UUID(user_id)

    statement = select(User).where(User.uid == user_uuid)
    result = await session.exec(statement)
    user = result.first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not verify_password(password_change.old_password, user.password_hash):
        raise HTTPException(status_code=400, detail="Old password is incorrect")

    new_password_hash = generate_hash_password(password_change.new_password)
    user.password_hash = new_password_hash

    await session.commit()
    await session.refresh(user)

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"message": "Password changed successfully"}
    )

@auth_router.post("/forgot-password")
async def forgot_password(payload: ForgotPasswordRequest, session: AsyncSession = Depends(get_session)):
    user = await user_service.get_user_by_email(payload.email, session)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    otp = generate_otp()
    await store_otp(payload.email, otp)
    send_otp_email(payload.email, otp)

    return {"message": "OTP sent to email."}

@auth_router.post("/verify-otp")
async def verify_otp(payload: VerifyOTPRequest):
    stored_otp = await get_stored_otp(payload.email)
    if not stored_otp or stored_otp != payload.otp:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    return {"message": "OTP verified successfully."}

@auth_router.post("/reset-password")
async def reset_password(payload: ResetPasswordRequest, session: AsyncSession = Depends(get_session)):
    stored_otp = await get_stored_otp(payload.email)
    if not stored_otp or stored_otp != payload.otp:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    user = await user_service.get_user_by_email(payload.email, session)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password_hash = generate_hash_password(payload.new_password)
    await session.commit()
    await delete_otp(payload.email)

    return {"message": "Password reset successful."}

 

supabase = create_client(Config.SUPABASE_URL, Config.SUPABASE_KEY)


 

@auth_router.post("/upload-profile-image")
async def upload_profile_image(
    file: UploadFile = File(...),
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session),
):
    user_id = token_data.get("sub")
    print(f"Decoded token user ID: {user_id}")
    user_uuid = uuid.UUID(user_id)

    statement = select(User).where(User.uid == user_uuid)
    result = await session.exec(statement)
    user = result.first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if file.content_type is None :
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Only JPEG, JPG, and PNG are allowed."
        )

    file_content = await file.read()
    file_name = f"{user.uid}/{file.filename}"

    print(f"Uploading file: {file.filename}, size: {len(file_content)} bytes, content_type: {file.content_type}")

     
    response = supabase.storage.from_("profile-images").upload(
        file_name,
        file_content,
        {"contentType": file.content_type}
    )

    if not response:
        raise HTTPException(status_code=500, detail="Upload failed. No response from Supabase.")

    public_url = supabase.storage.from_("profile-images").get_public_url(file_name)

    print(f"Public URL: {public_url}")

    user.profile_image_url = public_url
    await session.commit()
    await session.refresh(user)

    return {
        "message": "Profile image uploaded successfully",
        "profile_image_url": public_url,
    }


@auth_router.post("/guest-login")
async def guest_login():
     
    guest_user_data = {
        "uid": f"guest_{uuid.uuid4()}",
        "email": f"guest_{random.randint(1000, 9999)}@volunshare.com",
        "guest": True  # marker to identify this is a guest user
    }

    access_token = create_access_token(guest_user_data)
    refresh_token = create_access_token(guest_user_data, refresh=True, expiry=timedelta(days=REFRESH_TOKEN_EXPIRY))

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "message": "Guest login successful",
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": guest_user_data
        }
    )

