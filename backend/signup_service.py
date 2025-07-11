"""
signup_service.py – FastAPI-Registrierungs-Service für die Med-App

Voraussetzungen:
    pip install fastapi uvicorn pymongo python-dotenv passlib[bcrypt] pyjwt python-multipart

Starten mit:
    uvicorn signup_service:app --reload
"""

import jwt
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
import os
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

from backend.db import users_collection

# ---------- Config ----------
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = os.getenv("JWT_SECRET", "devsecret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MIN = 60 * 24  # 24h

app = FastAPI(title="Med-App Signup Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- Pydantic-Schemes ----------
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    password_confirm: str
    firstname: str
    lastname: str
    med_id: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# ---------- Helper ----------
def create_access_token(sub: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MIN)
    payload = {"sub": sub, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

# ---------- Routes ----------
@app.post("/register", response_model=TokenResponse)
def register(data: RegisterRequest):
    email = data.email.lower().strip()

    if data.password != data.password_confirm:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passwords do not match",
        )

    # Prüfen, ob Nutzer schon existiert
    if users_collection.find_one({"email": email}):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="E-Mail already registered",
        )

    hashed_pw = pwd_context.hash(data.password)

    result = users_collection.insert_one({
        "email": email,
        "password": hashed_pw,
        "firstname": data.firstname.strip(),
        "lastname": data.lastname.strip(),
        "med_id": data.med_id.strip(),
        "created_at": datetime.utcnow(),
    })

    token = create_access_token(str(result.inserted_id))
    return {"access_token": token, "token_type": "bearer"}

@app.get("/ping")
def ping():
    return {"msg": "pong"}
