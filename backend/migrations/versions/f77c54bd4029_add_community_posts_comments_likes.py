"""Add community posts, comments, likes

Revision ID: f77c54bd4029
Revises: 5265d271f294
Create Date: 2025-06-23 00:16:03.399401

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel
import sqlalchemy.dialects.postgresql as pg
import uuid


# revision identifiers, used by Alembic.
revision: str = 'f77c54bd4029'
down_revision: Union[str, None] = '5265d271f294'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    # Posts table
    op.create_table(
        'posts',
        sa.Column('id', pg.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, nullable=False),
        sa.Column('user_id', pg.UUID(as_uuid=True), sa.ForeignKey('users.uid'), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.func.now(), nullable=False),
    )
    
    # Comments table
    op.create_table(
        'comments',
        sa.Column('id', pg.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, nullable=False),
        sa.Column('post_id', pg.UUID(as_uuid=True), sa.ForeignKey('posts.id'), nullable=False),
        sa.Column('user_id', pg.UUID(as_uuid=True), sa.ForeignKey('users.uid'), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.func.now(), nullable=False),
    )
    
    # Likes table
    op.create_table(
        'likes',
        sa.Column('id', pg.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, nullable=False),
        sa.Column('user_id', pg.UUID(as_uuid=True), sa.ForeignKey('users.uid'), nullable=False),
        sa.Column('post_id', pg.UUID(as_uuid=True), sa.ForeignKey('posts.id'), nullable=True),
        sa.Column('comment_id', pg.UUID(as_uuid=True), sa.ForeignKey('comments.id'), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.func.now(), nullable=False),
    )

def downgrade():
    op.drop_table('likes')
    op.drop_table('comments')
    op.drop_table('posts')