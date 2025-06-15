from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from db import users_collection  # dein MongoDB-Collection-Objekt

app = FastAPI()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    firstname: str
    lastname: str
    med_id: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password) -> bool:
    return pwd_context.verify(plain_password, hashed_password)



@app.post("/register")
async def register(user: RegisterRequest):
    # Check if user exists
    existing_user = users_collection.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="Benutzer mit dieser E-Mail existiert bereits.")

    hashed_pw = hash_password(user.password)
    user_dict = user.dict()
    user_dict["password"] = hashed_pw

    # Insert user
    users_collection.insert_one(user_dict)

    return {"success": True, "message": "Benutzer erfolgreich registriert."}



@app.post("/login")
async def login(credentials: LoginRequest):
    user = users_collection.find_one({"email": credentials.email})
    if not user:
        raise HTTPException(status_code=400, detail="Benutzer nicht gefunden.")

    if not verify_password(credentials.password, user["password"]):
        raise HTTPException(status_code=400, detail="Falsches Passwort.")

    # User zurückgeben ohne Passwort
    user_out = {
        "email": user["email"],
        "firstname": user["firstname"],
        "lastname": user["lastname"],
        "med_id": user["med_id"]
    }

    return {"success": True, "message": "Login erfolgreich.", "user": user_out}
