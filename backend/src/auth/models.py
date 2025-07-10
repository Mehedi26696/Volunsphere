from sqlmodel import SQLModel , Field, Column
import sqlalchemy.dialects.postgresql as pg
import uuid
from datetime import datetime
from typing import Optional

from typing import List, TYPE_CHECKING
from sqlmodel import Relationship

if TYPE_CHECKING:
    from src.community.models import Post, Comment, Like


class User(SQLModel, table=True):
    """User model for authentication and user management."""
    __tablename__ = "users"
    uid: uuid.UUID  = Field(
        sa_column= Column(
            pg.UUID,
            nullable=False,
            primary_key=True,
            default=uuid.uuid4
        )
    )
    username: str = Field(
        sa_column=Column(
            pg.VARCHAR(50),
            nullable=False,
            unique=True
        )
    )
    email: str = Field(
        sa_column=Column(
            pg.VARCHAR(255),
            nullable=False,
            unique=True
        )
    )
    first_name: str
    last_name: str
    city: str
    country: str
    phone: str = Field(default=None, nullable=True)
    is_verified: bool = Field(default=False)
    password_hash: str = Field(exclude=True)
    profile_image_url: Optional[str] = Field(default=None, nullable=True)
    fcm_token: Optional[str] = Field(default=None, nullable=True)
    created_at: datetime = Field(
        sa_column = Column(
            pg.TIMESTAMP,
            default=datetime.now 
        )
    )
    updated_at: datetime = Field(
        sa_column = Column(
            pg.TIMESTAMP,
            default=datetime.now 
        )
    )


    posts: List["Post"] = Relationship(back_populates="user")
    comments: List["Comment"] = Relationship(back_populates="user")
    likes: List["Like"] = Relationship(back_populates="user")


    def __repr__(self):
        return f"<User {self.username}>"