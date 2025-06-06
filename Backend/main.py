from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import bcrypt
import json
import os

app = FastAPI()

DATA_FILE = "users.json"

class UserIn(BaseModel):
    email: str
    password: str

def load_users():
    if not os.path.exists(DATA_FILE):
        return {}
    with open(DATA_FILE, "r") as f:
        return json.load(f)

def save_users(users):
    with open(DATA_FILE, "w") as f:
        json.dump(users, f)

@app.post("/register")
async def register(user: UserIn):
    users = load_users()
    if user.email in users:
        raise HTTPException(status_code=400, detail="User already exists")
    hashed_pw = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())
    users[user.email] = hashed_pw.decode('utf-8')
    save_users(users)
    return {"message": "Registration successful"}

@app.post("/login")
async def login(user: UserIn):
    users = load_users()
    if user.email not in users:
        print("invalid")
    hashed_pw = users[user.email].encode('utf-8')
    if not bcrypt.checkpw(user.password.encode('utf-8'), hashed_pw):
        raise HTTPException(status_code=400, detail="Ungültige E-Mail oder Passwort")
    return {"message": "Login erfolgreich"}
