from fastapi.security import HTTPBearer
 
from fastapi.security import HTTPAuthorizationCredentials
from fastapi import Request,status
from src.auth.utils import decode_token
from fastapi.exceptions import HTTPException
from src.db.redis import is_jti_blocked 
from fastapi import WebSocket, WebSocketException



class TokenBearer(HTTPBearer):
    
    def __init__(self, auto_error = True):
        super().__init__(auto_error=auto_error)


    async def __call__(self, request: Request) -> HTTPAuthorizationCredentials:
       
       creds =  await super().__call__(request)        
         
       token = creds.credentials

       token_data = decode_token(token)
       
       if not self.token_valid(token):
              raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                 detail ={
                    "error": "Invalid token",
                    "resolution": "Please login again to obtain a new token"
                }
                 
              )
       if await is_jti_blocked(token_data.get('jti')):
              raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail ={
                    "error": "Token has been revoked",
                    "resolution": "Please login again to obtain a new token"
                }
                 
              )
       self.verify_token_data(token_data)

       return token_data
    def token_valid(self, token: str) -> bool:
        token_data = decode_token(token)
        return token_data is not None
    
    
    def verify_token_data(self, token_data):
        raise NotImplementedError("This method should be implemented by subclasses.")

    
class AccessTokenBearer(TokenBearer):
    
    def verify_token_data(self, token_data: dict) -> None:
        if token_data and token_data['refresh']:
           raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Please provide a access token for this endpoint"
                 
            )
        

class RefreshTokenBearer(TokenBearer):
    def verify_token_data(self, token_data: dict) -> None:
        if token_data and not token_data['refresh']:
           raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Please provide a refresh token for this endpoint"
                 
            )
        

 
        
class AccessTokenFromWSBearer(TokenBearer):
    async def __call__(self, websocket: WebSocket) -> dict:
        token = websocket.query_params.get("token")
        if not token:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Missing token")

        token_data = decode_token(token)
        if not token_data:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")

        if await is_jti_blocked(token_data.get("jti")):
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Token revoked")

        self.verify_token_data(token_data)
        return token_data

    def verify_token_data(self, token_data: dict) -> None:
        if token_data.get("refresh", False):
            raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Access token required")
        if not token_data.get("ws", False):
            raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="WebSocket permission missing")
