
from .models import User
from .schemas import UserCreateModel
from .utils import generate_hash_password
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlmodel import select



class UserService:
    async def get_user_by_email(self,email: str, session: AsyncSession):
        
        statement = select(User).where(User.email == email)

        result = await session.exec(statement)
        user = result.first()

        return user
    
     
    
    async def user_exists(self,email, session: AsyncSession):
        
        user = await self.get_user_by_email(email, session)
        
        if user:
            return True
        return False
    
    async def user_exists_by_username(self, username: str, session: AsyncSession):
         
        statement = select(User).where(User.username == username)

        result = await session.exec(statement)
        user = result.first()

        if user:
            return True
        return False
    
    async def create_user(self, user_data: UserCreateModel, session: AsyncSession):
        
        user_data_dict = user_data.model_dump()

 

        new_user = User(**user_data_dict)

        new_user.password_hash = generate_hash_password(user_data_dict['password'])
        session.add(new_user)
        await session.commit()

        return new_user 
    
    async def get_current_user_id(self, user: User):
        
        if not user:
            return None
        return str(user.uid)
    
   

 