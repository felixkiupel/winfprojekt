from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from typing import List, Optional
from datetime import datetime, timedelta
from contextlib import asynccontextmanager
from pydantic import BaseModel, EmailStr
from jose import JWTError, jwt
from passlib.context import CryptContext
from bson import ObjectId
import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, messaging

# ─── ENV & INITIAL SETUP ─────────────────────────────────────────────────────────

load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY", "change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# MongoDB
from backend.db import users_collection, db
tokens_collection   = db["tokens"]
messages_collection = db["messages"]

# Firebase
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json"))
firebase_admin.initialize_app(cred)

# FastAPI app
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting up MedApp Push Service…")
    yield
    print("Shutting down…")

app = FastAPI(title="MedApp Push Service", lifespan=lifespan)

# CORS (allow your frontend/origins here)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth utils
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        uid: str = payload.get("sub")
        if uid is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return uid
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

async def send_fcm_notification(title: str, body: str, data: dict, tokens: List[str]):
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data=data,
        tokens=tokens,
    )
    resp = messaging.send_multicast(message)
    return {"success_count": resp.success_count, "failure_count": resp.failure_count}


# ─── Pydantic MODELS ───────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    firstname: str
    lastname: str
    med_id: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class FCMTokenRegistration(BaseModel):
    user_id: str
    fcm_token: str

class PushNotification(BaseModel):
    title: str
    body: str
    data: Optional[dict] = {}
    user_ids: Optional[List[str]] = None
    community_id: Optional[str] = None
    broadcast: bool = False

class HealthMessageIn(BaseModel):
    title: str
    content: str
    community_id: str
    priority: str = "normal"

class MessageReadStatus(BaseModel):
    message_id: str
    user_id: str


# ─── ROUTES ────────────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {"message": "MedApp Push Service API", "version": "1.0.0"}

# 1) Registration → MongoDB users collection
@app.post("/register", status_code=201)
async def register(req: RegisterRequest):
    email = req.email.lower().strip()
    if users_collection.find_one({"email": email}):
        raise HTTPException(400, "Email already registered")
    users_collection.insert_one({
        "email":     email,
        "password":  hash_password(req.password),
        "firstname": req.firstname,
        "lastname":  req.lastname,
        "med_id":    req.med_id,
    })
    return {"message": "User created"}

# 2) Login → issue JWT
@app.post("/token")
async def login_endpoint(form: LoginRequest):
    email = form.email.lower().strip()
    user = users_collection.find_one({"email": email})
    if not user or not verify_password(form.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token({"sub": str(user["_id"])})
    return {"access_token": token, "token_type": "bearer"}

# Alias /login → /token
@app.post("/login")
async def login_alias(form: LoginRequest):
    return await login_endpoint(form)

# 3) Persist FCM tokens
@app.post("/register-fcm-token")
async def register_fcm_token(req: FCMTokenRegistration, uid: str = Depends(get_current_user)):
    tokens_collection.update_one(
        {"user_id": req.user_id},
        {"$addToSet": {"fcm_tokens": req.fcm_token}},
        upsert=True
    )
    return {"status": "success"}

# 4) Push endpoint (unchanged path)
@app.post("/admin/send-push")
async def send_push(notification: PushNotification, uid: str = Depends(get_current_user)):
    # gather tokens
    tokens = []
    if notification.broadcast:
        doc = tokens_collection.find({})
        for d in doc:
            tokens.extend(d.get("fcm_tokens", []))
    else:
        for u in notification.user_ids or []:
            d = tokens_collection.find_one({"user_id": u})
            tokens.extend(d.get("fcm_tokens", [])) if d else None

    fcm_res = await send_fcm_notification(notification.title, notification.body, notification.data, tokens)

    # websocket & return
    # … (leave your existing ws broadcast here) …
    return {"status": "success", "fcm_result": fcm_res}

# 5) Create Health Message → MongoDB “messages”
@app.post("/admin/health-message")
async def create_health_message(msg: HealthMessageIn, uid: str = Depends(get_current_user)):
    doc = msg.dict()
    doc.update({
        "sent_by":    uid,
        "created_at": datetime.utcnow(),
        "read_by":    []
    })
    result = messages_collection.insert_one(doc)
    message_id = str(result.inserted_id)
    # … your push + ws broadcast …
    return {"status": "success", "message_id": message_id}

# 6) List messages
@app.get("/messages")
async def get_messages(community_id: Optional[str] = None, uid: str = Depends(get_current_user)):
    query = {}
    if community_id:
        query["community_id"] = community_id
    cursor = messages_collection.find(query).sort("created_at", -1)

    out = []
    for d in cursor:
        out.append({
            "id":         str(d["_id"]),
            "title":      d["title"],
            "content":    d["content"],
            "community":  d["community_id"],
            "priority":   d["priority"],
            "created_at": d["created_at"].isoformat(),
            "is_read":    uid in d.get("read_by", [])
        })
    return {"messages": out}

# 7) Mark as read
@app.post("/messages/read")
async def mark_message_read(req: MessageReadStatus, uid: str = Depends(get_current_user)):
    res = messages_collection.update_one(
        {"_id": ObjectId(req.message_id)},
        {"$addToSet": {"read_by": uid}}
    )
    if res.matched_count == 0:
        raise HTTPException(404, "Message not found")
    # … ws broadcast if you still want …
    return {"status": "success"}

# 8) WebSocket endpoint (unchanged)
@app.websocket("/ws/{user_id}")
async def websocket_endpoint(ws: WebSocket, user_id: str):
    # … your existing ConnectionManager logic …
    pass


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)