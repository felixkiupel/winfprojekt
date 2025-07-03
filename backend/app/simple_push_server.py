"""
Einfacher Push Notification Server für MedApp
MIT Community-basierter Nachrichtenfilterung
OHNE Firebase, OHNE Datenbank - nur WebSocket und REST API
"""

from fastapi import FastAPI, WebSocket, HTTPException, Body, Header, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Optional, Set
from datetime import datetime, timedelta
import json
import asyncio
from pydantic import BaseModel, EmailStr
import logging
import random
import string
from functools import wraps
import hashlib
import hmac
from enum import Enum

# Logging Setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("MedApp-Push")

# FastAPI App
app = FastAPI(title="MedApp Push Server with Community Support")

# CORS für Flutter und Browser
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Erlaubt alle Origins für Entwicklung
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],  # Wichtig für Browser
)

# Community Enum
class Community(str, Enum):
    ALL = "all_communities"
    ABORIGINAL_HEALTH = "aboriginal_health"
    TORRES_STRAIT = "torres_strait"
    REMOTE = "remote_communities"
    URBAN_INDIGENOUS = "urban_indigenous"

# Pydantic Models
class PushNotification(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, str]] = {}
    user_ids: Optional[List[str]] = None
    broadcast: bool = True
    community_id: Optional[str] = Community.ALL

class DeviceToken(BaseModel):
    user_id: str
    device_id: str
    community_id: Optional[str] = Community.ALL
    
class HealthMessage(BaseModel):
    title: str
    content: str
    priority: str = "normal"  # normal, high, urgent
    community_id: Optional[str] = Community.ALL

class DeleteAccountRequest(BaseModel):
    user_id: str
    confirmation_code: str

class RequestDeleteAccount(BaseModel):
    user_id: str
    email: EmailStr

class UserCommunityUpdate(BaseModel):
    user_id: str
    community_id: str

# In-Memory Storage (später MongoDB)
websocket_connections: Dict[str, WebSocket] = {}
device_tokens: Dict[str, Dict] = {}  # user_id -> {device_id, community_id}
messages: List[Dict] = []  # Gespeicherte Nachrichten mit community_id
user_data: Dict[str, Dict] = {}  # user_id -> {email, community_id, etc}
deletion_codes: Dict[str, Dict] = {}  # user_id -> {code, expiry, email}
audit_log: List[Dict] = []  # Audit trail
user_communities: Dict[str, str] = {}  # user_id -> community_id mapping

# Simple JWT simulation (in production use proper JWT)
def verify_token(authorization: Optional[str] = Header(None)):
    """Simulate JWT token verification"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid or missing token")
    
    token = authorization.replace("Bearer ", "")
    
    if token == "invalid_token":
        raise HTTPException(status_code=401, detail="Invalid token")
    
    return token

# WebSocket Manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
    
    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        logger.info(f"✅ User {user_id} connected via WebSocket")
        
        # Get user's community
        community_id = user_communities.get(user_id, Community.ALL)
        
        await self.send_to_user(user_id, {
            "type": "connected",
            "message": f"Verbunden als {user_id}",
            "community": community_id,
            "timestamp": datetime.now().isoformat()
        })
    
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            logger.info(f"👋 User {user_id} disconnected")
    
    async def disconnect_user(self, user_id: str):
        """Force disconnect a user (for account deletion)"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].close()
            except:
                pass
            self.disconnect(user_id)
    
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
    
    async def send_to_community(self, message: dict, community_id: str):
        """Send message to all users in a specific community"""
        success_count = 0
        disconnected = []
        
        for user_id, connection in self.active_connections.items():
            user_community = user_communities.get(user_id, Community.ALL)
            
            # Send if user is in the target community or has "all_communities"
            if community_id == Community.ALL or user_community == community_id or user_community == Community.ALL:
                try:
                    await connection.send_json(message)
                    success_count += 1
                except Exception:
                    disconnected.append(user_id)
        
        # Remove disconnected users
        for user_id in disconnected:
            self.disconnect(user_id)
            
        return success_count
    
    async def broadcast(self, message: dict):
        """Broadcast to all connected users"""
        return await self.send_to_community(message, Community.ALL)

manager = ConnectionManager()

# Helper Functions
def generate_confirmation_code() -> str:
    """Generate a 6-digit confirmation code"""
    return ''.join(random.choices(string.digits, k=6))

def send_email_code(email: str, code: str):
    """Simulate sending email with confirmation code"""
    logger.info(f"📧 Email sent to {email} with code: {code}")

def delete_all_user_data(user_id: str) -> Dict:
    """Delete all user data from the system"""
    deleted_data = {
        "messages": 0,
        "devices": 0,
        "settings": 0,
        "connections": 0
    }
    
    # Delete messages
    global messages
    original_count = len(messages)
    messages = [msg for msg in messages if msg.get('user_id') != user_id]
    deleted_data["messages"] = original_count - len(messages)
    
    # Delete device tokens
    if user_id in device_tokens:
        del device_tokens[user_id]
        deleted_data["devices"] = 1
    
    # Delete user data
    if user_id in user_data:
        del user_data[user_id]
        deleted_data["settings"] = 1
    
    # Delete community mapping
    if user_id in user_communities:
        del user_communities[user_id]
    
    # Close WebSocket connections
    if user_id in manager.active_connections:
        deleted_data["connections"] = 1
    
    return deleted_data

def filter_messages_by_community(messages_list: List[Dict], user_community: str) -> List[Dict]:
    """Filter messages based on user's community"""
    if user_community == Community.ALL:
        return messages_list
    
    filtered = []
    for msg in messages_list:
        msg_community = msg.get('community_id', Community.ALL)
        # Include message if it's for all communities or matches user's community
        if msg_community == Community.ALL or msg_community == user_community:
            filtered.append(msg)
    
    return filtered

# API Endpoints
@app.get("/")
async def root():
    return {
        "status": "running",
        "message": "MedApp Push Server with Community Support",
        "version": "1.1.0",
        "active_connections": len(manager.active_connections),
        "registered_devices": len(device_tokens),
        "total_messages": len(messages),
        "communities": [c.value for c in Community]
    }

@app.options("/{rest_of_path:path}")
async def preflight_handler(rest_of_path: str):
    """Handle CORS preflight requests"""
    return {"message": "OK"}

@app.post("/register-device")
async def register_device(device: DeviceToken):
    """Register device with community preference"""
    device_tokens[device.user_id] = {
        "device_id": device.device_id,
        "community_id": device.community_id
    }
    
    # Update user community mapping
    user_communities[device.user_id] = device.community_id
    
    logger.info(f"📱 Device registered for user: {device.user_id} in community: {device.community_id}")
    return {"status": "success", "message": "Device registered", "community": device.community_id}

@app.put("/user/community")
async def update_user_community(
    update: UserCommunityUpdate,
    token: str = Depends(verify_token)
):
    """Update user's community preference"""
    user_communities[update.user_id] = update.community_id
    
    # Update device token if exists
    if update.user_id in device_tokens:
        device_tokens[update.user_id]["community_id"] = update.community_id
    
    # Notify user about community change
    await manager.send_to_user(update.user_id, {
        "type": "community_updated",
        "community_id": update.community_id,
        "timestamp": datetime.now().isoformat()
    })
    
    logger.info(f"👥 User {update.user_id} switched to community: {update.community_id}")
    return {
        "status": "success",
        "user_id": update.user_id,
        "community_id": update.community_id
    }

@app.get("/communities")
async def get_communities():
    """Get list of available communities"""
    return {
        "communities": [
            {
                "id": c.value,
                "name": c.value.replace("_", " ").title(),
                "description": get_community_description(c)
            }
            for c in Community
        ]
    }

def get_community_description(community: Community) -> str:
    """Get description for each community"""
    descriptions = {
        Community.ALL: "Receive updates from all communities",
        Community.ABORIGINAL_HEALTH: "Aboriginal health services and cultural programs",
        Community.TORRES_STRAIT: "Torres Strait Islander community updates",
        Community.REMOTE: "Remote and rural community health services",
        Community.URBAN_INDIGENOUS: "Urban Indigenous health and social services"
    }
    return descriptions.get(community, "")

@app.post("/send-push")
async def send_push(notification: PushNotification):
    """Send push notification with community targeting"""
    logger.info(f"📤 Sending push: {notification.title} to community: {notification.community_id}")
    
    # Save message with community_id
    message_data = {
        "id": f"msg_{len(messages)}_{datetime.now().timestamp()}",
        "title": notification.title,
        "body": notification.body,
        "data": notification.data,
        "community_id": notification.community_id,
        "timestamp": datetime.now().isoformat(),
        "priority": notification.data.get("priority", "normal"),
        "read_by": []
    }
    messages.append(message_data)
    
    # WebSocket message
    ws_message = {
        "type": "push_notification",
        "notification": message_data
    }
    
    # Send based on targeting
    success_count = 0
    if notification.broadcast:
        # Send to all users in the specified community
        success_count = await manager.send_to_community(ws_message, notification.community_id)
    elif notification.user_ids:
        # Send to specific users if they're in the right community
        for user_id in notification.user_ids:
            user_community = user_communities.get(user_id, Community.ALL)
            # Check if user should receive this notification
            if (notification.community_id == Community.ALL or 
                user_community == Community.ALL or 
                user_community == notification.community_id):
                if await manager.send_to_user(user_id, ws_message):
                    success_count += 1
    
    return {
        "status": "success",
        "delivered_to": success_count,
        "community": notification.community_id,
        "total_connections": len(manager.active_connections),
        "message": message_data
    }

@app.post("/send-health-message")
async def send_health_message(message: HealthMessage):
    """Create health message for specific community"""
    notification = PushNotification(
        title=f"🏥 {message.title}",
        body=message.content[:100] + "..." if len(message.content) > 100 else message.content,
        data={
            "type": "health_message",
            "priority": message.priority,
            "full_content": message.content
        },
        broadcast=True,
        community_id=message.community_id
    )
    
    return await send_push(notification)

@app.get("/messages")
async def get_messages(
    limit: int = 20,
    community: Optional[str] = Query(None, description="Filter by community ID"),
    user_id: Optional[str] = Query(None, description="User ID for personalized filtering")
):
    """Get messages with optional community filter"""
    # Determine which community to filter by
    if community:
        # Explicit community filter
        filter_community = community
    elif user_id:
        # Use user's community preference
        filter_community = user_communities.get(user_id, Community.ALL)
    else:
        # No filter - return all
        filter_community = Community.ALL
    
    # Filter messages
    filtered_messages = filter_messages_by_community(messages, filter_community)
    
    # Sort by timestamp (newest first)
    sorted_messages = sorted(filtered_messages, key=lambda x: x['timestamp'], reverse=True)
    
    return {
        "messages": sorted_messages[:limit],
        "total": len(sorted_messages),
        "filtered_by": filter_community,
        "available_communities": [c.value for c in Community]
    }

@app.get("/messages/stats")
async def get_message_stats():
    """Get statistics about messages per community"""
    stats = {}
    for community in Community:
        community_messages = filter_messages_by_community(messages, community.value)
        stats[community.value] = {
            "count": len(community_messages),
            "unread": sum(1 for msg in community_messages if len(msg.get('read_by', [])) == 0),
            "users": len([uid for uid in user_communities.values() if uid == community.value])
        }
    
    return {
        "stats": stats,
        "total_messages": len(messages),
        "total_users": len(user_communities)
    }

@app.post("/messages/{message_id}/read")
async def mark_message_read(message_id: str, user_id: str = Body(...)):
    """Mark message as read"""
    for msg in messages:
        if msg['id'] == message_id:
            if user_id not in msg['read_by']:
                msg['read_by'].append(user_id)
            
            # Notify about read status
            await manager.broadcast({
                "type": "message_read",
                "message_id": message_id,
                "user_id": user_id,
                "timestamp": datetime.now().isoformat()
            })
            
            return {"status": "success"}
    
    raise HTTPException(status_code=404, detail="Message not found")

@app.delete("/messages")
async def clear_messages(
    community: Optional[str] = Query(None, description="Clear only messages from specific community")
):
    """Clear messages (optionally by community)"""
    global messages
    
    if community:
        # Clear only messages from specific community
        original_count = len(messages)
        messages = [msg for msg in messages if msg.get('community_id') != community]
        deleted_count = original_count - len(messages)
        return {
            "status": "success",
            "message": f"Cleared {deleted_count} messages from community: {community}"
        }
    else:
        # Clear all messages
        count = len(messages)
        messages.clear()
        return {"status": "success", "message": f"All {count} messages cleared"}

# User Deletion Endpoints (unchanged)
@app.post("/user/request-delete")
async def request_account_deletion(
    request: RequestDeleteAccount,
    token: str = Depends(verify_token)
):
    """Request account deletion - sends 2FA code"""
    user_id = request.user_id
    email = request.email
    
    code = generate_confirmation_code()
    
    deletion_codes[user_id] = {
        "code": code,
        "email": email,
        "expiry": datetime.now() + timedelta(minutes=10),
        "attempts": 0
    }
    
    send_email_code(email, code)
    
    audit_log.append({
        "action": "deletion_requested",
        "user_id": user_id,
        "timestamp": datetime.now().isoformat(),
        "ip": "127.0.0.1"
    })
    
    return {
        "status": "success",
        "message": "Confirmation code sent to email",
        "expires_in": 600
    }

@app.delete("/user/delete")
async def delete_account(
    request: DeleteAccountRequest,
    token: str = Depends(verify_token)
):
    """Delete user account with 2FA confirmation"""
    user_id = request.user_id
    confirmation_code = request.confirmation_code
    
    if user_id not in deletion_codes:
        raise HTTPException(
            status_code=400,
            detail="No deletion request found. Please request deletion first."
        )
    
    code_data = deletion_codes[user_id]
    
    if datetime.now() > code_data["expiry"]:
        del deletion_codes[user_id]
        raise HTTPException(
            status_code=400,
            detail="Confirmation code expired. Please request deletion again."
        )
    
    if code_data["attempts"] >= 3:
        del deletion_codes[user_id]
        raise HTTPException(
            status_code=429,
            detail="Too many failed attempts. Please request deletion again."
        )
    
    if confirmation_code != code_data["code"]:
        deletion_codes[user_id]["attempts"] += 1
        raise HTTPException(
            status_code=400,
            detail=f"Invalid confirmation code. {3 - code_data['attempts']} attempts remaining."
        )
    
    logger.info(f"🗑️ Deleting all data for user: {user_id}")
    
    await manager.disconnect_user(user_id)
    deleted_stats = delete_all_user_data(user_id)
    del deletion_codes[user_id]
    
    audit_entry = {
        "action": "account_deleted",
        "user_id": user_id,
        "timestamp": datetime.now().isoformat(),
        "deleted_items": deleted_stats,
        "ip": "127.0.0.1"
    }
    audit_log.append(audit_entry)
    
    send_deletion_confirmation_email(code_data["email"], user_id)
    
    return {
        "status": "success",
        "message": "Account successfully deleted",
        "deleted_items": deleted_stats,
        "audit_id": len(audit_log) - 1
    }

def send_deletion_confirmation_email(email: str, user_id: str):
    """Send confirmation email after account deletion"""
    logger.info(f"📧 Deletion confirmation sent to {email}")

@app.get("/admin/audit-log")
async def get_audit_log(
    limit: int = 50,
    token: str = Depends(verify_token)
):
    """Get audit log for deletions (admin only)"""
    return {
        "logs": audit_log[-limit:],
        "total": len(audit_log)
    }

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """WebSocket connection for real-time updates"""
    await manager.connect(user_id, websocket)
    
    try:
        while True:
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                
                if message.get("type") == "ping":
                    await websocket.send_json({"type": "pong", "timestamp": datetime.now().isoformat()})
                
                elif message.get("type") == "get_unread_count":
                    # Count unread messages for user's community
                    user_community = user_communities.get(user_id, Community.ALL)
                    community_messages = filter_messages_by_community(messages, user_community)
                    unread = sum(1 for msg in community_messages if user_id not in msg.get('read_by', []))
                    
                    await websocket.send_json({
                        "type": "unread_count",
                        "count": unread,
                        "community": user_community,
                        "timestamp": datetime.now().isoformat()
                    })
                
                elif message.get("type") == "update_community":
                    # Handle community update via WebSocket
                    new_community = message.get("community_id")
                    if new_community in [c.value for c in Community]:
                        user_communities[user_id] = new_community
                        await websocket.send_json({
                            "type": "community_updated",
                            "community_id": new_community,
                            "timestamp": datetime.now().isoformat()
                        })
                
                else:
                    await websocket.send_json({
                        "type": "echo",
                        "data": message,
                        "timestamp": datetime.now().isoformat()
                    })
                    
            except json.JSONDecodeError:
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
    """Enhanced statistics with community breakdown"""
    now = datetime.now()
    today = now.date()
    
    today_messages = [
        msg for msg in messages 
        if datetime.fromisoformat(msg['timestamp']).date() == today
    ]
    
    total_with_reads = sum(1 for msg in messages if len(msg.get('read_by', [])) > 0)
    read_rate = (total_with_reads / len(messages) * 100) if messages else 100
    
    deletion_requests_today = sum(
        1 for log in audit_log 
        if log['action'] == 'deletion_requested' 
        and datetime.fromisoformat(log['timestamp']).date() == today
    )
    
    deletions_today = sum(
        1 for log in audit_log 
        if log['action'] == 'account_deleted' 
        and datetime.fromisoformat(log['timestamp']).date() == today
    )
    
    # Community statistics
    community_stats = {}
    for community in Community:
        community_users = [uid for uid, comm in user_communities.items() if comm == community.value]
        community_messages = [msg for msg in messages if msg.get('community_id') == community.value]
        community_stats[community.value] = {
            "users": len(community_users),
            "messages": len(community_messages),
            "messages_today": len([msg for msg in community_messages 
                                 if datetime.fromisoformat(msg['timestamp']).date() == today])
        }
    
    return {
        "total_messages": len(messages),
        "messages_today": len(today_messages),
        "active_connections": len(manager.active_connections),
        "registered_devices": len(device_tokens),
        "read_rate": round(read_rate, 1),
        "deletion_requests_today": deletion_requests_today,
        "deletions_completed_today": deletions_today,
        "pending_deletions": len(deletion_codes),
        "community_breakdown": community_stats,
        "server_uptime": "N/A",
    }

if __name__ == "__main__":
    import uvicorn
    logger.info("🚀 Starting MedApp Push Server with Community Support...")
    logger.info("📱 WebSocket: ws://localhost:8000/ws/{user_id}")
    logger.info("👥 Communities: " + ", ".join([c.value for c in Community]))
    logger.info("🗑️ Delete Endpoint: DELETE /user/delete")
    logger.info("📊 API Docs: http://localhost:8000/docs")
    logger.info("✨ Community-based message filtering enabled!")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)