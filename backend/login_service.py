"""
login_service.py – FastAPI-Login-Service für die Med-App

Voraussetzungen
---------------
pip install fastapi uvicorn pymongo python-dotenv passlib[bcrypt] pyjwt python-multipart


Starten: uvicorn login_service:app --reload
"""


import jwt
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from passlib.context import CryptContext
from pydantic import BaseModel
import os
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

from db import users_collection

# ---------- Konfiguration ----------
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = os.getenv("JWT_SECRET", "devsecret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MIN = 60 * 24  # 24 Stunden

app = FastAPI(title="Med-App Login Service")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- Pydantic-Schemas ----------
class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# ---------- Helper ----------
def verify_password(plain_pw: str, hashed_pw: str) -> bool:
    """Vergleicht Klartext-PW gegen Bcrypt-Hash."""
    try:
        return pwd_context.verify(plain_pw, hashed_pw)
    except Exception:
        return False

def create_access_token(sub: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MIN)
    payload = {"sub": sub, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

# ---------- Routes ----------
@app.post("/login", response_model=TokenResponse)
def login(data: LoginRequest):
    user = users_collection.find_one({"email": data.email.lower().strip()})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nutzer existiert nicht",
        )
    if not verify_password(data.password, user["password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falsches Passwort",
        )
    token = create_access_token(str(user["_id"]))
    return {"access_token": token, "token_type": "bearer"}

@app.get("/ping")
def ping():
    return {"msg": "pong"}



####  curl -X POST http://127.0.0.1:8000/login \
 ###   -H "Content-Type: application/json" \
    ###   -d '{"email":"test@test.com","password":""}'


## source venv/bin/activate
## uvicorn login_service:app --reload

