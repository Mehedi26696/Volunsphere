from sqlmodel import SQLModel, Field, Column, Relationship
from sqlalchemy import ForeignKey  # ✅ Use this
import sqlalchemy.dialects.postgresql as pg
from typing import Optional, List
import uuid
from datetime import datetime
from src.auth.models import User  # Import User model for relationships



class Post(SQLModel, table=True):
    __tablename__ = "posts"
    id: uuid.UUID = Field(
        sa_column=Column(pg.UUID, primary_key=True, default=uuid.uuid4, nullable=False)
    )
    user_id: uuid.UUID = Field(
        sa_column=Column(pg.UUID, ForeignKey("users.uid"), nullable=False)
    )
    content: str = Field(sa_column=Column(pg.TEXT, nullable=False))
    created_at: datetime = Field(
        sa_column=Column(pg.TIMESTAMP, default=datetime.now, nullable=False)
    )
    updated_at: datetime = Field(
        sa_column=Column(pg.TIMESTAMP, default=datetime.now, nullable=False)
    )

    user: Optional["User"] = Relationship(back_populates="posts")
    comments: List["Comment"] = Relationship(back_populates="post")
    likes: List["Like"] = Relationship(back_populates="post")


class Comment(SQLModel, table=True):
    __tablename__ = "comments"
    id: uuid.UUID = Field(
        sa_column=Column(pg.UUID, primary_key=True, default=uuid.uuid4, nullable=False)
    )
    post_id: uuid.UUID = Field(
        sa_column=Column(pg.UUID, ForeignKey("posts.id"), nullable=False)
    )
    user_id: uuid.UUID = Field(
        sa_column=Column(pg.UUID, ForeignKey("users.uid"), nullable=False)
    )
    content: str = Field(sa_column=Column(pg.TEXT, nullable=False))
    created_at: datetime = Field(
        sa_column=Column(pg.TIMESTAMP, default=datetime.now, nullable=False)
    )

    post: Optional[Post] = Relationship(back_populates="comments")
    user: Optional["User"] = Relationship()
    likes: List["Like"] = Relationship(back_populates="comment")


class Like(SQLModel, table=True):
    __tablename__ = "likes"
    id: uuid.UUID = Field(
        sa_column=Column(pg.UUID, primary_key=True, default=uuid.uuid4, nullable=False)
    )
    user_id: uuid.UUID = Field(
        sa_column=Column(pg.UUID, ForeignKey("users.uid"), nullable=False)
    )
    post_id: Optional[uuid.UUID] = Field(
        sa_column=Column(pg.UUID, ForeignKey("posts.id"), nullable=True),
        default=None
    )
    comment_id: Optional[uuid.UUID] = Field(
        sa_column=Column(pg.UUID, ForeignKey("comments.id"), nullable=True),
        default=None
    )
    created_at: datetime = Field(
        sa_column=Column(pg.TIMESTAMP, default=datetime.now, nullable=False)
    )

    post: Optional[Post] = Relationship(back_populates="likes")
    comment: Optional[Comment] = Relationship(back_populates="likes")
    user: Optional["User"] = Relationship(back_populates="likes")   

