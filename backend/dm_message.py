from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import List
from datetime import datetime
from bson import ObjectId

from backend.db import dm_collection
from backend.auth_utils import get_current_patient

# Router für Direct Messages
router = APIRouter(
    prefix="/dm",
    tags=["direct-message"],
)

# Eingangsmodell für Chat-Nachrichten
class ChatMessageIn(BaseModel):
    date: datetime
    text: str

# Ausgangsmodell: wandelt _id → id um
class ChatMessageOut(BaseModel):
    id: str = Field(..., alias="_id")
    date: datetime
    senderId: str
    text: str

@router.get("/{partner_id}/messages", response_model=List[ChatMessageOut])
def get_dm_messages(
        partner_id: str,
        current_user: dict = Depends(get_current_patient),
):
    """
    Liefert alle Nachrichten zwischen eingeloggtem User und partner_id, sortiert nach Datum aufsteigend.
    """
    # eigene ID aus Token
    my_id = current_user.get("med_id") or str(current_user.get("_id"))
    # Query für beidseitige DM
    cursor = dm_collection.find({
        "$or": [
            {"senderId": my_id, "receiverId": partner_id},
            {"senderId": partner_id, "receiverId": my_id},
        ]
    }).sort("date", 1)

    out = []
    for doc in cursor:
        doc["_id"] = str(doc.get("_id"))
        out.append({
            "_id": doc["_id"],
            "date": doc["date"],
            "senderId": doc.get("senderId"),
            "text": doc.get("text"),
        })
    return out

@router.post("/{partner_id}/messages", status_code=status.HTTP_201_CREATED, response_model=ChatMessageOut)
def send_dm_message(
        partner_id: str,
        msg: ChatMessageIn,
        current_user: dict = Depends(get_current_patient),
):
    """
    Sendet eine neue DM vom eingeloggten User an partner_id.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))
    doc = {
        "date": msg.date,
        "text": msg.text,
        "senderId": my_id,
        "receiverId": partner_id,
    }
    result = dm_collection.insert_one(doc)
    doc["_id"] = str(result.inserted_id)
    return doc
