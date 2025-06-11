from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import bcrypt
from db import users_collection

app = FastAPI()

class UserIn(BaseModel):
    name: str
    surname: str
    email: str
    medical_id: str
    password: str

@app.post("/register")
async def register(user: UserIn):
    if users_collection.find_one({"email": user.email}):
        raise HTTPException(status_code=400, detail="User already exists")

    hashed_pw = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())

    users_collection.insert_one({
        "name": user.name,
        "surname": user.surname,
        "email": user.email,
        "medical_id": user.medical_id,
        "password": hashed_pw.decode('utf-8')
    })

    return {"message": "Registration successful"}

@app.post("/login")
async def login(user: UserIn):
    db_user = users_collection.find_one({"email": user.email})
    if not db_user:
        raise HTTPException(status_code=400, detail="Invalid email or password")

    hashed_pw = db_user["password"].encode('utf-8')
    if not bcrypt.checkpw(user.password.encode('utf-8'), hashed_pw):
        raise HTTPException(status_code=400, detail="Invalid email or password")

    return {"message": f"Login successful. Welcome, {db_user['name']}!"}
