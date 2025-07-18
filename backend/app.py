from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, EmailStr, Field
from typing import List
from datetime import datetime



# DB-Collections
from backend.db import patients_collection, com_messages_collection, community_collection, doctors_collection, \
    dm_collection
# Auth-Helper
from backend.auth_utils import verify_password, create_access_token, pwd_context, get_current_patient

# Patient-Router
from backend.patient import router as patient_router

# Community-Router
from backend.community import router as community_router
from backend.dm_message import router as dm_message_router
from backend.com_message import router as com_message_router
from backend.auth_service import  router as auth_service_router



# Env laden
load_dotenv()

app = FastAPI(title="Med-App inkl. Community & Messaging")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OAuth2-Token-Extraktion
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")


# ---------- AUTH-SCHEMAS ----------

class LoginRequest(BaseModel):
    email: str
    password: str

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

class PatientProfile(BaseModel):
    firstname: str
    lastname: str
    med_id: str


# ---------- MESSAGE-SCHEMAS ----------

class MessageIn(BaseModel):
    date: datetime
    community: str
    title: str
    message: str

class MessageOut(BaseModel):
    id: str = Field(..., alias="_id")
    date: datetime
    community: str
    title: str
    message: str




# ---------- PATIENT-ROUTER ----------
app.include_router(patient_router)

# ---------- DIRECT-MESSAGE ----------
app.include_router(dm_message_router)

# ---------- COM-MESSAGE ----------
app.include_router(com_message_router)
app.include_router(auth_service_router)



# ---------- COMMUNITY-ROUTER ----------
# Der Prefix in community.py ist "/community",
# Man kann ihn in community.py auf "/communitys" ändern,
# damit  Flutter-App nicht umgestellt werden muss.
app.include_router(community_router)
