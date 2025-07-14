

from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from uuid import UUID


class UserRead(BaseModel):
    uid: UUID
    username: str
    profile_image_url: Optional[str] = None

    model_config = {
        "from_attributes": True  
    }


class PostCreate(BaseModel):
    content: str


class PostRead(BaseModel):
    id: UUID
    user_id: UUID
    user: UserRead  
    content: str
    created_at: datetime
    updated_at: datetime
    likes_count: int
    comments_count: int
    liked_by_me: bool = False

    model_config = {
        "from_attributes": True   
    }

class CommentCreate(BaseModel):
    content: str


class CommentRead(BaseModel):
    id: UUID
    post_id: UUID
    user_id: UUID
    user: UserRead   
    content: str
    created_at: datetime

    model_config = {
        "from_attributes": True   
    }

class LikeRead(BaseModel):
    id: UUID
    post_id: UUID
    user_id: UUID
    created_at: datetime

    model_config = {
        "from_attributes": True   
    }

# Update schemas for editing
class PostUpdate(BaseModel):
    content: str

class CommentUpdate(BaseModel):
    content: str