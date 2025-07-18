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


# ---------- Helper Functions ----------

def verify_password(plain_pw: str, hashed_pw: str) -> bool:
    """
    Compares a plain-text password with a bcrypt-hashed version stored in the database.

    Returns:
        True if the password matches, otherwise False.

    Example:
        User types "mypassword123" — compare it against the stored bcrypt hash.
    """
    try:
        return pwd_context.verify(plain_pw, hashed_pw)
    except Exception:
        # If something goes wrong (e.g., invalid hash), we safely return False
        return False


def create_access_token(sub: str) -> str:
    """
    Generates a JWT access token that includes:
    - 'sub': the user ID (subject of the token)
    - 'exp': the expiration timestamp

    This token is returned to the frontend after login or registration.
    It's digitally signed using our secret key and can't be tampered with.

    Args:
        sub (str): User ID to embed in the token.

    Returns:
        A JWT access token as a string.
    """
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MIN)
    payload = {"sub": sub, "exp": expire}

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def get_current_patient(token: str = Depends(oauth2_scheme)) -> dict:
    """
    Dependency for protected endpoints. Extracts the current user from a JWT token.

    Steps:
    1. Reads the "Authorization: Bearer <token>" header
    2. Decodes and verifies the token using the secret key
    3. Loads the user from the MongoDB collection based on the user ID

    Raises:
        - HTTP 401 if the token is invalid or expired
        - HTTP 404 if the user doesn't exist

    Returns:
        A dictionary representing the current user from the database.
    """
    try:
        # Decode the token using the secret key and algorithm
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")

        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    # Fetch the user from the database using the extracted ID
    patient = patients_collection.find_one({"_id": ObjectId(user_id)})

    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return patient
