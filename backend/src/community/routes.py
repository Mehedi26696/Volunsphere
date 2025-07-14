
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select, SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession
from typing import List
from uuid import UUID

from src.auth.dependencies import AccessTokenBearer
from src.db.main import get_session
from src.community.models import Post, Comment, Like
from src.community.schemas import PostCreate, PostRead, CommentCreate, CommentRead

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from src.chat.websocket_manager import WebSocketManager
from src.community.schemas import PostCreate, PostRead, CommentCreate, CommentRead,UserRead
from sqlalchemy.orm import selectinload
from src.auth.utils import decode_token
from datetime import datetime
from fastapi import Query
import json
from src.community.schemas import PostUpdate, CommentUpdate

 

community_router = APIRouter()


manager = WebSocketManager()


@community_router.post("/posts", response_model=PostRead)
async def create_post(
    payload: PostCreate,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    post = Post(content=payload.content, user_id=user_id)
    session.add(post)
    await session.commit()
    await session.refresh(post)

    return await get_post(post.id, session)


from sqlalchemy.orm import selectinload

@community_router.get("/posts", response_model=List[PostRead])
async def list_posts(
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    stmt = (
        select(Post)
        .options(
            selectinload(Post.user),
            selectinload(Post.likes),       
            selectinload(Post.comments),    
        )
        .order_by(Post.created_at.desc())
    )
    posts = (await session.exec(stmt)).all()

    result = []
    for post in posts:
        liked_stmt = select(Like).where(Like.post_id == post.id, Like.user_id == user_id)
        liked = (await session.exec(liked_stmt)).first()
        result.append(PostRead(
            id=post.id,
            user_id=post.user_id,
            user=post.user,
            content=post.content,
            created_at=post.created_at,
            updated_at=post.updated_at,
            likes_count=len(post.likes),
            comments_count=len(post.comments),
            liked_by_me=liked is not None
        ))
    return result




@community_router.get("/posts/{post_id}", response_model=PostRead)
async def get_post(post_id: UUID, session: AsyncSession = Depends(get_session)):
    stmt = (
        select(Post)
        .where(Post.id == post_id)
        .options(
            selectinload(Post.user),        
            selectinload(Post.comments),
            selectinload(Post.likes)
        )
    )
    result = await session.exec(stmt)
    post = result.first()

    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    return PostRead(
        id=post.id,
        user_id=post.user_id,
        user=UserRead.model_validate(post.user),  
        content=post.content,
        created_at=post.created_at,
        updated_at=post.updated_at,
        likes_count=len(post.likes),
        comments_count=len(post.comments)
    )



@community_router.post("/posts/{post_id}/comments", response_model=CommentRead)
async def comment_post(
    post_id: UUID,
    payload: CommentCreate,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    comment = Comment(post_id=post_id, user_id=user_id, content=payload.content)
    session.add(comment)
    await session.commit()
    await session.refresh(comment)

    # Load user eagerly
    await session.refresh(comment, attribute_names=["user"])

    return comment


@community_router.get("/posts/{post_id}/comments", response_model=List[CommentRead])
async def list_comments(post_id: UUID, session: AsyncSession = Depends(get_session)):
    stmt = select(Comment).where(Comment.post_id == post_id).options(selectinload(Comment.user))
    result = await session.exec(stmt)
    comments = result.all()

    return comments 



@community_router.post("/posts/{post_id}/like", status_code=201)
async def like_post(
    post_id: UUID,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    existing_stmt = select(Like).where(Like.post_id == post_id, Like.user_id == user_id)
    existing_like = (await session.exec(existing_stmt)).first()
    if existing_like:
        raise HTTPException(status_code=400, detail="Already liked")

    like = Like(post_id=post_id, user_id=user_id)
    session.add(like)
    await session.commit()
    return {"message": "Liked post"}


@community_router.post("/posts/{post_id}/unlike", status_code=200)
async def unlike_post(
    post_id: UUID,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    stmt = select(Like).where(Like.post_id == post_id, Like.user_id == user_id)
    like = (await session.exec(stmt)).first()
    if not like:
        raise HTTPException(status_code=404, detail="Like not found")

    await session.delete(like)
    await session.commit()
    return {"message": "Unliked post"}


@community_router.delete("/posts/{post_id}", status_code=204)
async def delete_post(
    post_id: UUID,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    post = await session.get(Post, post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")
    await session.delete(post)
    await session.commit()
    return {"message": "Post deleted successfully"}


@community_router.delete("/posts/{post_id}/comments/{comment_id}", status_code=200)
async def delete_comment(
    post_id: UUID,
    comment_id: UUID,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    comment = await session.get(Comment, comment_id)

    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    if comment.user_id != user_id:
        raise HTTPException(status_code=403, detail="You can only delete your own comment.")
    if comment.post_id != post_id:
        raise HTTPException(status_code=400, detail="Comment does not belong to this post.")

    await session.delete(comment)
    await session.commit()
    return {"message": "Comment deleted successfully"}



# Edit post route


@community_router.put("/posts/{post_id}", response_model=PostRead)
async def edit_post(
    post_id: UUID,
    payload: PostUpdate,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    post = await session.get(Post, post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.user_id != user_id:
        raise HTTPException(status_code=403, detail="You can only edit your own post.")
    post.content = payload.content
    post.updated_at = datetime.now()
    session.add(post)
    await session.commit()
    await session.refresh(post)
    return await get_post(post.id, session)

# Edit comment route
@community_router.put("/posts/{post_id}/comments/{comment_id}", response_model=CommentRead)
async def edit_comment(
    post_id: UUID,
    comment_id: UUID,
    payload: CommentUpdate,
    token_data: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    user_id = UUID(token_data["sub"])
    comment = await session.get(Comment, comment_id)
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    if comment.user_id != user_id:
        raise HTTPException(status_code=403, detail="You can only edit your own comment.")
    if comment.post_id != post_id:
        raise HTTPException(status_code=400, detail="Comment does not belong to this post.")
    comment.content = payload.content
    session.add(comment)
    await session.commit()
    await session.refresh(comment)
    await session.refresh(comment, attribute_names=["user"])
    return comment