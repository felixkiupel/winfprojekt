# Standard library imports for working with environment variables and timestamps
import os
from datetime import datetime, timedelta

# Library for creating and verifying JWTs (JSON Web Tokens)
import jwt

# FastAPI imports for dependency injection, HTTP errors, and response status codes
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

# Passlib helps securely hash and verify passwords using bcrypt
from passlib.context import CryptContext

# Needed to work with MongoDB ObjectIds
from bson import ObjectId

# Reference to the MongoDB users collection
from backend.db import patients_collection


# ---------- Configuration ----------

# Configure the password hashing algorithm (bcrypt is a secure, industry-standard option)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Secret key for signing JWTs (should come from .env in production)
SECRET_KEY = os.getenv("JWT_SECRET", "devsecret")

# Algorithm used to sign JWTs — HMAC using SHA-256 is standard and secure
ALGORITHM = "HS256"

# Token expiration in minutes (here: 24 hours)
ACCESS_TOKEN_EXPIRE_MIN = 60 * 24

# Defines how the app expects to receive a token: via "Authorization: Bearer <token>" header
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")


# ---------- Password Hashing ----------

def verify_password(plain_pw: str, hashed_pw: str) -> bool:
    """Compare plain text vs hashed password."""
    try:
        return pwd_context.verify(plain_pw, hashed_pw)
    except Exception:
        return False


def hash_password(password: str) -> str:
    """Hash a password with bcrypt."""
    return pwd_context.hash(password)


# ---------- JWT Creation ----------

def create_access_token(sub: str) -> str:
    """
    Creates a JWT token with:
    - 'sub' as the user_id
    - 'exp' expiration timestamp
    """
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MIN)
    payload = {"sub": sub, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# ---------- JWT Decoding ----------

def get_user_from_token(token: str) -> ObjectId:
    """
    Decodes a JWT and returns the MongoDB ObjectId for the user.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
        return ObjectId(user_id)

    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


def get_current_patient(token: str = Depends(oauth2_scheme)) -> dict:
    """
    Dependency for protected routes:
    - Decodes JWT
    - Fetches user directly from DB
    """
    user_id = get_user_from_token(token)
    patient = patients_collection.find_one({"_id": user_id})
    if not patient:
        raise HTTPException(status_code=404, detail="User not found")
    return patient
