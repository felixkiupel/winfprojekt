from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import json
import asyncio
from contextlib import asynccontextmanager
import firebase_admin
from firebase_admin import credentials, messaging
from pydantic import BaseModel
from jose import JWTError, jwt
import os
from dotenv import load_dotenv
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Initialize Firebase Admin SDK
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json"))
firebase_admin.initialize_app(cred)

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}
        self.user_tokens: Dict[str, str] = {}  # user_id -> FCM token

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_connections:
            self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_personal_message(self, message: str, user_id: str):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                await connection.send_text(message)

    async def broadcast(self, message: str, community_id: Optional[str] = None):
        # In a real app, you'd filter by community_id
        for user_id, connections in self.active_connections.items():
            for connection in connections:
                await connection.send_text(message)

    def register_fcm_token(self, user_id: str, fcm_token: str):
        self.user_tokens[user_id] = fcm_token

    def get_fcm_token(self, user_id: str) -> Optional[str]:
        return self.user_tokens.get(user_id)

manager = ConnectionManager()

# Pydantic models
class PushNotification(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, str]] = {}
    user_ids: Optional[List[str]] = None
    community_id: Optional[str] = None
    broadcast: bool = False

class HealthMessage(BaseModel):
    id: Optional[str] = None
    title: str
    content: str
    community_id: str
    created_at: Optional[datetime] = None
    priority: str = "normal"  # normal, high, urgent
    read_by: Optional[List[str]] = []

class FCMTokenRegistration(BaseModel):
    fcm_token: str
    user_id: str

class MessageReadStatus(BaseModel):
    message_id: str
    user_id: str

# In-memory storage (replace with database in production)
messages_db: Dict[str, HealthMessage] = {}
read_status_db: Dict[str, List[str]] = {}  # message_id -> list of user_ids who read it

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Starting up MedApp Push Service...")
    yield
    # Shutdown
    print("Shutting down...")

app = FastAPI(title="MedApp Push Service", lifespan=lifespan)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Utility functions
def verify_token(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
            )
        return user_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )

async def send_fcm_notification(
    title: str,
    body: str,
    data: Dict[str, str],
    tokens: List[str]
) -> Dict[str, any]:
    """Send FCM push notification to multiple devices"""
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data,
        tokens=tokens,
    )
    
    try:
        response = messaging.send_multicast(message)
        return {
            "success_count": response.success_count,
            "failure_count": response.failure_count,
            "responses": response.responses
        }
    except Exception as e:
        print(f"Error sending FCM notification: {e}")
        return {"error": str(e)}

# API Endpoints
@app.get("/")
async def root():
    return {"message": "MedApp Push Service API", "version": "1.0.0"}

@app.post("/register-fcm-token")
async def register_fcm_token(
    token_data: FCMTokenRegistration,
    current_user: str = Depends(verify_token)
):
    """Register FCM token for push notifications"""
    manager.register_fcm_token(token_data.user_id, token_data.fcm_token)
    return {"status": "success", "message": "FCM token registered"}

@app.post("/admin/send-push")
async def send_push_notification(
    notification: PushNotification,
    current_user: str = Depends(verify_token)
):
    """Send push notification (Admin only)"""
    # TODO: Add admin role check
    
    tokens = []
    user_ids = []
    
    if notification.broadcast:
        # Send to all users
        tokens = list(manager.user_tokens.values())
        user_ids = list(manager.user_tokens.keys())
    elif notification.user_ids:
        # Send to specific users
        for user_id in notification.user_ids:
            token = manager.get_fcm_token(user_id)
            if token:
                tokens.append(token)
                user_ids.append(user_id)
    
    # Send FCM push notifications
    fcm_result = {}
    if tokens:
        fcm_result = await send_fcm_notification(
            title=notification.title,
            body=notification.body,
            data=notification.data,
            tokens=tokens
        )
    
    # Send WebSocket notifications
    message_data = {
        "type": "push_notification",
        "title": notification.title,
        "body": notification.body,
        "data": notification.data,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    if notification.broadcast:
        await manager.broadcast(json.dumps(message_data))
    else:
        for user_id in user_ids:
            await manager.send_personal_message(
                json.dumps(message_data),
                user_id
            )
    
    return {
        "status": "success",
        "fcm_result": fcm_result,
        "websocket_users": len(user_ids)
    }

@app.post("/admin/health-message")
async def create_health_message(
    message: HealthMessage,
    current_user: str = Depends(verify_token)
):
    """Create a new health message and send push notification"""
    # TODO: Add admin role check
    
    # Generate message ID and timestamp
    message.id = f"msg_{datetime.utcnow().timestamp()}"
    message.created_at = datetime.utcnow()
    message.read_by = []
    
    # Store message
    messages_db[message.id] = message
    
    # Send push notification
    notification = PushNotification(
        title=f"New Health Update: {message.title}",
        body=message.content[:100] + "..." if len(message.content) > 100 else message.content,
        data={
            "message_id": message.id,
            "type": "health_message",
            "priority": message.priority
        },
        community_id=message.community_id,
        broadcast=True  # Send to all users in community
    )
    
    push_result = await send_push_notification(notification, current_user)
    
    # Broadcast via WebSocket
    ws_message = {
        "type": "new_health_message",
        "message": message.dict(),
        "timestamp": datetime.utcnow().isoformat()
    }
    await manager.broadcast(json.dumps(ws_message), message.community_id)
    
    return {
        "status": "success",
        "message": message.dict(),
        "push_result": push_result
    }

@app.get("/messages")
async def get_messages(
    community_id: Optional[str] = None,
    current_user: str = Depends(verify_token)
):
    """Get all health messages for a community"""
    messages = []
    for msg_id, msg in messages_db.items():
        if community_id is None or msg.community_id == community_id:
            msg_dict = msg.dict()
            msg_dict["is_read"] = current_user in msg.read_by
            messages.append(msg_dict)
    
    # Sort by created_at descending
    messages.sort(key=lambda x: x["created_at"], reverse=True)
    return {"messages": messages}

@app.post("/messages/read")
async def mark_message_read(
    read_status: MessageReadStatus,
    current_user: str = Depends(verify_token)
):
    """Mark a message as read by the current user"""
    if read_status.message_id in messages_db:
        message = messages_db[read_status.message_id]
        if current_user not in message.read_by:
            message.read_by.append(current_user)
        
        # Send read status update via WebSocket
        ws_message = {
            "type": "message_read",
            "message_id": read_status.message_id,
            "user_id": current_user,
            "timestamp": datetime.utcnow().isoformat()
        }
        await manager.broadcast(json.dumps(ws_message))
        
        return {"status": "success", "message": "Message marked as read"}
    else:
        raise HTTPException(status_code=404, detail="Message not found")

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket, user_id)
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            
            # Handle ping/pong for connection keep-alive
            if data == "ping":
                await websocket.send_text("pong")
            else:
                # Process other messages if needed
                message = {
                    "type": "echo",
                    "data": data,
                    "timestamp": datetime.utcnow().isoformat()
                }
                await manager.send_personal_message(
                    json.dumps(message),
                    user_id
                )
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        print(f"User {user_id} disconnected")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)