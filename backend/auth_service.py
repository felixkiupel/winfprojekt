# Loads environment variables from a .env file (e.g., for secrets like JWT keys) and pydantic Field
from dotenv import load_dotenv

# FastAPI imports for building the web API
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer

# Pydantic is used to validate and parse incoming JSON data
from pydantic import BaseModel, EmailStr

# Database connection (MongoDB collection)
from backend.db import patients_collection

# Import the patient-related routes (GET endpoints)
from backend import patient

# Authentication helper functions and password handling logic
from backend.auth_utils import (
    verify_password,
    create_access_token,
    pwd_context,
)

# Load environment variables (used in auth_utils.py for secrets, DB URLs, etc.)
load_dotenv()

# Initialize the FastAPI application
app = FastAPI(title="Med-App Login Service")

# Allow requests from all origins (useful for frontend–backend communication)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Allow all origins (e.g. Flutter app)
    allow_credentials=True,       # Allow cookies/auth headers
    allow_methods=["*"],          # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],          # Allow all custom headers
)

# OAuth2 token extraction: expects the client to send a Bearer token in the header
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

# ---------- Data Schemas (Models) ----------

# Login input schema: required email + password
class LoginRequest(BaseModel):
    email: str
    password: str

# Registration input schema: all data needed to create a new patient account
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    password_confirm: str
    firstname: str
    lastname: str
    med_id: str


# Response schema after login or registration: contains the JWT
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"  # Standard type for OAuth2

# Profile schema for patients (returned in profile GET requests)
class PatientProfile(BaseModel):
    firstname: str
    lastname: str
    med_id: str


# ---------- Auth Routes ----------

# Login endpoint: verifies user credentials and returns a JWT token
@app.post("/login", response_model=TokenResponse)
def login(data: LoginRequest):
    # Try to find a user by email (case-insensitive, trimmed)
    user = patients_collection.find_one({"email": data.email.lower().strip()})

    # If user doesn't exist, return 401 Unauthorized
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User does not exist")

    # Check if the password is correct using bcrypt
    if not verify_password(data.password, user["password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Wrong password")

    # Create a JWT token containing the user's ID
    token = create_access_token(str(user["_id"]))

    # Return the token in the response
    return {"access_token": token, "token_type": "bearer"}


# Registration endpoint: creates a new user if validation passes
@app.post("/register", response_model=TokenResponse)
def register(data: RegisterRequest):
    email = data.email.lower().strip()

    # Check if both passwords match
    if data.password != data.password_confirm:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Passwords do not match")

    # Check if the email is already in use
    if patients_collection.find_one({"email": email}):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="E-Mail already registered")

    # Hash the password for secure storage
    hashed_pw = pwd_context.hash(data.password)

    # Insert new user data into the database
    result = patients_collection.insert_one({
        "email": email,
        "password": hashed_pw,
        "firstname": data.firstname.strip(),
        "lastname": data.lastname.strip(),
        "med_id": data.med_id.strip(),
    })

    # Generate JWT token for the newly created user
    token = create_access_token(str(result.inserted_id))
    return {"access_token": token, "token_type": "bearer"}


# Health check endpoint: use this to see if the backend is alive
@app.get("/ping")
def ping():
    return {"msg": "pong"}


# Include the GET routes from the patient module (e.g., /patient/me, /patient/all)
app.include_router(patient.router)
