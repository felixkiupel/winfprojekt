# backend/app.py

from fastapi import FastAPI, status
from pydantic import BaseModel, Field
from typing import List
from datetime import datetime
from bson import ObjectId

from backend.db import messages_collection

# Eingangs-Schema für PUT /messages
class MessageIn(BaseModel):
    date: datetime
    community: str
    title: str
    message: str

# Ausgangs-Schema für GET/PUT (wandelt _id → id um)
class MessageOut(BaseModel):
    id: str = Field(..., alias="_id")
    date: datetime
    community: str
    title: str
    message: str

app = FastAPI(title="Community-Messaging API")

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
    result = messages_collection.insert_one(doc)
    # Rückgabe: das frisch erzeugte Document mit String-ID
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
    cursor = messages_collection.find().sort("date", -1)
    out = []
    for doc in cursor:
        doc["_id"] = str(doc["_id"])
        out.append(doc)
    return out
