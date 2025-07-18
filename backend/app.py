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
from backend.dm_message import router as dm_router



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


# ---------- AUTH-ENDPOINTS ----------

@app.post("/login", response_model=TokenResponse)
def login(data: LoginRequest):
    user = patients_collection.find_one({"email": data.email.lower().strip()})
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User does not exist")
    if not verify_password(data.password, user["password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Wrong password")
    token = create_access_token(str(user["_id"]))
    return {"access_token": token, "token_type": "bearer"}


@app.post("/register", response_model=TokenResponse)
def register(data: RegisterRequest):
    email = data.email.lower().strip()
    if data.password != data.password_confirm:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Passwords do not match")
    if patients_collection.find_one({"email": email}):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="E-Mail already registered")
    hashed_pw = pwd_context.hash(data.password)
    result = patients_collection.insert_one({
        "email": email,
        "password": hashed_pw,
        "firstname": data.firstname.strip(),
        "lastname": data.lastname.strip(),
        "med_id": data.med_id.strip(),
        "role": "patient"
    })
    token = create_access_token(str(result.inserted_id))
    return {"access_token": token, "token_type": "bearer"}


@app.get("/ping")
def ping():
    return {"msg": "pong"}


# ---------- PATIENT-ROUTER ----------
app.include_router(patient_router)

# ---------- DIRECT-MESSAGE ----------
app.include_router(dm_router)



# ---------- COMMUNITY-ROUTER ----------
# Der Prefix in community.py ist "/community",
# Man kann ihn in community.py auf "/communitys" ändern,
# damit  Flutter-App nicht umgestellt werden muss.
app.include_router(community_router)



# ---------- MESSAGE-ENDPOINTS ----------

@app.put(
    "/messages",
    status_code=status.HTTP_201_CREATED,
    response_model=MessageOut,
)
async def log_message(msg: MessageIn):
    """
    Loggt eine neue Nachricht (PUT /messages).
    Body: { date, community, title, message }
    """
    doc = msg.dict()
    result = dm_collection.insert_one(doc)
    doc["_id"] = str(result.inserted_id)
    return doc


@app.get(
    "/messages",
    response_model=List[MessageOut],
)
async def get_messages():
    """
    Liefert alle geloggten Nachrichten, sortiert nach Datum absteigend.
    """
    cursor = dm_collection.find().sort("date", -1)
    out = []
    for doc in cursor:
        doc["_id"] = str(doc["_id"])
        out.append(doc)
    return out
