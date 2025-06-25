from typing import Dict, Set
from fastapi import WebSocket, WebSocketDisconnect


class WebSocketManager:
    def __init__(self):
     
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, room: str, websocket: WebSocket):
        await websocket.accept()
        if room not in self.active_connections:
            self.active_connections[room] = set()
        self.active_connections[room].add(websocket)

    def disconnect(self, room: str, websocket: WebSocket):
        connections = self.active_connections.get(room)
        if connections:
            connections.discard(websocket)
            if not connections:
                del self.active_connections[room]

    async def send_personal_message(self, message: str, websocket: WebSocket):
        try:
            await websocket.send_text(message)
        except WebSocketDisconnect:
           
            pass
        except Exception as e:
            print(f"[Error] Failed to send personal message: {e}")

    async def broadcast(self, room: str, message: str):
        connections = self.active_connections.get(room, set()).copy()
        for connection in connections:
            try:
                await connection.send_text(message)
            except WebSocketDisconnect:
                self.disconnect(room, connection)
            except Exception as e:
                print(f"[Error] Broadcast failed: {e}")
                self.disconnect(room, connection)
