
from pydantic import BaseModel,Field, EmailStr
import uuid
from datetime import datetime
from datetime import date
from typing import Optional


class UserCreateModel(BaseModel):
    username: str = Field(min_length=3, max_length=50) # Username must be between 3 and 50 characters
    email: str = Field(max_length=30) # Email must be a valid email format
    first_name: str = Field(min_length=2, max_length=50) # First name must be between 2 and 50 characters   
    last_name: str = Field(min_length=2, max_length=50) # Last name must be between 2 and 50 characters
    city: str = Field(default=None, nullable=True)  # City can be optional
    country: str = Field(default=None, nullable=True)  # Country can be optional
    phone: str = Field(default=None, nullable=True)  # Phone can be optional
    password: str  = Field(min_length=4) # Password must be between 6 and 128 characters


class UserModel(BaseModel):
    uid: uuid.UUID  
    username: str
    email: str
    first_name: str
    last_name: str
    city: str = Field(default=None, nullable=True)  # City can be optional
    country: str = Field(default=None, nullable=True)  # Country can be optional
    phone: str = Field(default=None, nullable=True)  # Phone can be optional
    is_verified: bool 
    password_hash: str = Field(exclude=True)
    profile_image_url: Optional[str] = None   
    created_at: datetime  
    updated_at: datetime  

class UserLoginModel(BaseModel):
    email: str = Field(max_length=30)  # Email must be a valid email format
    password: str = Field(min_length=4)  # Password must be at least 4 characters long

class UserUpdateModel(BaseModel):
    username: Optional[str]
    email: Optional[str]
    first_name: Optional[str]
    last_name: Optional[str]
    city: Optional[str]
    country: Optional[str]
    phone: Optional[str]
 

class PasswordChangeRequest(BaseModel):
    old_password: str
    new_password: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otp: str

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str





