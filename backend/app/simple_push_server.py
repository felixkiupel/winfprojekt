"""
Einfacher Push Notification Server für MedApp
OHNE Firebase, OHNE Datenbank - nur WebSocket und REST API
"""

from fastapi import FastAPI, WebSocket, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Optional, Set
from datetime import datetime
import json
import asyncio
from pydantic import BaseModel
import logging

# Logging Setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("MedApp-Push")

# FastAPI App
app = FastAPI(title="MedApp Push Server")

# CORS für Flutter und Browser
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Erlaubt alle Origins für Entwicklung
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],  # Wichtig für Browser
)

# Pydantic Models
class PushNotification(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, str]] = {}
    user_ids: Optional[List[str]] = None
    broadcast: bool = True

class DeviceToken(BaseModel):
    user_id: str
    device_id: str
    
class HealthMessage(BaseModel):
    title: str
    content: str
    priority: str = "normal"  # normal, high, urgent

# In-Memory Storage (später MongoDB)
websocket_connections: Dict[str, WebSocket] = {}
device_tokens: Dict[str, str] = {}  # user_id -> device_id
messages: List[Dict] = []  # Gespeicherte Nachrichten

# WebSocket Manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
    
    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        logger.info(f"✅ User {user_id} connected via WebSocket")
        
        # Sende Willkommensnachricht
        await self.send_to_user(user_id, {
            "type": "connected",
            "message": f"Verbunden als {user_id}",
            "timestamp": datetime.now().isoformat()
        })
    
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            logger.info(f"👋 User {user_id} disconnected")
    
    async def send_to_user(self, user_id: str, message: dict):
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_json(message)
                return True
            except Exception as e:
                logger.error(f"Error sending to {user_id}: {e}")
                self.disconnect(user_id)
                return False
        return False
    
    async def broadcast(self, message: dict):
        disconnected = []
        success_count = 0
        
        for user_id, connection in self.active_connections.items():
            try:
                await connection.send_json(message)
                success_count += 1
            except Exception:
                disconnected.append(user_id)
        
        # Entferne disconnected users
        for user_id in disconnected:
            self.disconnect(user_id)
            
        return success_count

manager = ConnectionManager()

# API Endpoints
@app.get("/")
async def root():
    return {
        "status": "running",
        "message": "MedApp Push Server",
        "version": "1.0.0",
        "active_connections": len(manager.active_connections),
        "registered_devices": len(device_tokens),
        "total_messages": len(messages)
    }

@app.options("/{rest_of_path:path}")
async def preflight_handler(rest_of_path: str):
    """Handle CORS preflight requests"""
    return {"message": "OK"}

@app.post("/register-device")
async def register_device(device: DeviceToken):
    """Gerät registrieren (für spätere Push-Implementierung)"""
    device_tokens[device.user_id] = device.device_id
    logger.info(f"📱 Device registered for user: {device.user_id}")
    return {"status": "success", "message": "Device registered"}

@app.post("/send-push")
async def send_push(notification: PushNotification):
    """Push-Benachrichtigung über WebSocket senden"""
    logger.info(f"📤 Sending push: {notification.title}")
    
    # Nachricht speichern
    message_data = {
        "id": f"msg_{len(messages)}_{datetime.now().timestamp()}",
        "title": notification.title,
        "body": notification.body,
        "data": notification.data,
        "timestamp": datetime.now().isoformat(),
        "priority": notification.data.get("priority", "normal"),
        "read_by": []  # Für Read-Status tracking
    }
    messages.append(message_data)
    
    # WebSocket Nachricht vorbereiten
    ws_message = {
        "type": "push_notification",
        "notification": message_data
    }
    
    # Senden
    success_count = 0
    if notification.broadcast:
        success_count = await manager.broadcast(ws_message)
    elif notification.user_ids:
        for user_id in notification.user_ids:
            if await manager.send_to_user(user_id, ws_message):
                success_count += 1
    
    return {
        "status": "success",
        "delivered_to": success_count,
        "total_connections": len(manager.active_connections),
        "message": message_data
    }

@app.post("/send-health-message")
async def send_health_message(message: HealthMessage):
    """Health Message erstellen und als Push senden"""
    notification = PushNotification(
        title=f"🏥 {message.title}",
        body=message.content[:100] + "..." if len(message.content) > 100 else message.content,
        data={
            "type": "health_message",
            "priority": message.priority,
            "full_content": message.content
        },
        broadcast=True
    )
    
    return await send_push(notification)

@app.get("/messages")
async def get_messages(limit: int = 20):
    """Letzte Nachrichten abrufen"""
    # Sortiere nach Timestamp (neueste zuerst)
    sorted_messages = sorted(messages, key=lambda x: x['timestamp'], reverse=True)
    return {
        "messages": sorted_messages[:limit],
        "total": len(messages)
    }

@app.post("/messages/{message_id}/read")
async def mark_message_read(message_id: str, user_id: str = Body(...)):
    """Nachricht als gelesen markieren"""
    for msg in messages:
        if msg['id'] == message_id:
            if user_id not in msg['read_by']:
                msg['read_by'].append(user_id)
            
            # Benachrichtige andere Clients
            await manager.broadcast({
                "type": "message_read",
                "message_id": message_id,
                "user_id": user_id,
                "timestamp": datetime.now().isoformat()
            })
            
            return {"status": "success"}
    
    raise HTTPException(status_code=404, detail="Message not found")

@app.delete("/messages")
async def clear_messages():
    """Alle Nachrichten löschen (für Testing)"""
    messages.clear()
    return {"status": "success", "message": "All messages cleared"}

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """WebSocket Verbindung für Real-time Updates"""
    await manager.connect(user_id, websocket)
    
    try:
        while True:
            # Warte auf Nachrichten vom Client
            data = await websocket.receive_text()
            
            # Handle verschiedene Message Types
            try:
                message = json.loads(data)
                
                if message.get("type") == "ping":
                    # Ping-Pong für Keep-Alive
                    await websocket.send_json({"type": "pong", "timestamp": datetime.now().isoformat()})
                
                elif message.get("type") == "get_unread_count":
                    # Zähle ungelesene Nachrichten
                    unread = sum(1 for msg in messages if user_id not in msg.get('read_by', []))
                    await websocket.send_json({
                        "type": "unread_count",
                        "count": unread,
                        "timestamp": datetime.now().isoformat()
                    })
                
                else:
                    # Echo andere Nachrichten
                    await websocket.send_json({
                        "type": "echo",
                        "data": message,
                        "timestamp": datetime.now().isoformat()
                    })
                    
            except json.JSONDecodeError:
                # Plain text message (backward compatibility)
                if data == "ping":
                    await websocket.send_text("pong")
                else:
                    await websocket.send_json({
                        "type": "echo",
                        "data": data,
                        "timestamp": datetime.now().isoformat()
                    })
                    
    except Exception as e:
        logger.error(f"WebSocket error for {user_id}: {e}")
    finally:
        manager.disconnect(user_id)

# Admin Stats Endpoint
@app.get("/stats")
async def get_stats():
    """Statistiken für Admin Dashboard"""
    now = datetime.now()
    today = now.date()
    
    # Nachrichten heute
    today_messages = [
        msg for msg in messages 
        if datetime.fromisoformat(msg['timestamp']).date() == today
    ]
    
    # Durchschnittliche Read-Rate
    total_with_reads = sum(1 for msg in messages if len(msg.get('read_by', [])) > 0)
    read_rate = (total_with_reads / len(messages) * 100) if messages else 100
    
    return {
        "total_messages": len(messages),
        "messages_today": len(today_messages),
        "active_connections": len(manager.active_connections),
        "registered_devices": len(device_tokens),
        "read_rate": round(read_rate, 1),
        "server_uptime": "N/A",  # Könnte später implementiert werden
    }

if __name__ == "__main__":
    import uvicorn
    logger.info("🚀 Starting MedApp Push Server (Simplified Version)...")
    logger.info("📱 WebSocket: ws://localhost:8000/ws/{user_id}")
    logger.info("📊 API Docs: http://localhost:8000/docs")
    logger.info("✨ Keine Firebase, keine DB - nur pure WebSocket Power!")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)