# Loads environment variables from a .env file
from dotenv import load_dotenv

# FastAPI imports
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer

# Pydantic for request/response models
from pydantic import BaseModel, EmailStr

# MongoDB collection
from backend.db import patients_collection

# Import the patient-related routes (GET endpoints)
from backend import patient

# Auth helpers
from backend.auth_utils import (
    verify_password,
    create_access_token,
    pwd_context,
    get_user_from_token  # now available!
)

# Encryption helpers
from backend.crypto_utils import encrypt_field, decrypt_field

# Load env
load_dotenv()

# FastAPI app
app = FastAPI(title="Med-App Login Service")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

# ---------- Models ----------

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

# ---------- Routes ----------

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

    enc_firstname = encrypt_field(data.firstname.strip())
    enc_lastname  = encrypt_field(data.lastname.strip())
    enc_med_id    = encrypt_field(data.med_id.strip())

    result = patients_collection.insert_one({
        "email": email,
        "password": hashed_pw,
        "firstname": enc_firstname,
        "lastname": enc_lastname,
        "med_id": enc_med_id,
    })

    token = create_access_token(str(result.inserted_id))
    return {"access_token": token, "token_type": "bearer"}


@app.get("/profile", response_model=PatientProfile)
def get_profile(token: str = Depends(oauth2_scheme)):
    user_id = get_user_from_token(token)
    user = patients_collection.find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return PatientProfile(
        firstname=decrypt_field(user["firstname"]),
        lastname=decrypt_field(user["lastname"]),
        med_id=decrypt_field(user["med_id"])
    )


@app.get("/ping")
def ping():
    return {"msg": "pong"}

# Include other patient routes
app.include_router(patient.router)
