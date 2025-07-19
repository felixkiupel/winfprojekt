from dotenv import load_dotenv
load_dotenv()

from fastapi import APIRouter, Depends, status, Response
from pydantic import BaseModel, Field
from typing import List
from datetime import datetime

from backend.crypto_utils import encrypt_field, decrypt_field
from backend.db import dm_collection, patients_collection
from backend.auth_utils import get_current_patient
from backend.patient import PatientProfile

router = APIRouter(
    prefix="/dm",
    tags=["direct-message"],
)


# Eingangsmodell für Chat-Nachrichten (plaintext)
class ChatMessageIn(BaseModel):
    date: datetime
    text: str


# Ausgangsmodell: entschlüsselte Felder
class ChatMessageOut(BaseModel):
    id: str = Field(..., alias="_id")
    date: datetime
    senderId: str
    text: str
    read: bool


# Partner-Modell mit ungelesenem Count
class PartnerWithUnread(PatientProfile):
    unreadCount: int = Field(..., description="Anzahl der ungelesenen Nachrichten")


@router.get("/{partner_id}/messages", response_model=List[ChatMessageOut])
def get_dm_messages(
        partner_id: str,
        current_user: dict = Depends(get_current_patient),
):
    """
    Liefert alle Nachrichten zwischen eingeloggtem User und partner_id,
    sortiert nach Datum, entschlüsselt nur den Text.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))

    cursor = dm_collection.find({
        "$or": [
            {"senderId": my_id,      "receiverId": partner_id},
            {"senderId": partner_id, "receiverId": my_id},
        ]
    }).sort("date", 1)

    messages = []
    for doc in cursor:
        messages.append({
            "_id":    str(doc["_id"]),
            "date":   doc["date"],
            "senderId": doc["senderId"],               # im Klartext
            "text":     decrypt_field(doc["text"]),    # entschlüsselt
            "read":     doc.get("read", False),
        })
    return messages


@router.post(
    "/{partner_id}/messages",
    status_code=status.HTTP_201_CREATED,
    response_model=ChatMessageOut
)
def send_dm_message(
        partner_id: str,
        msg: ChatMessageIn,
        current_user: dict = Depends(get_current_patient),
):
    """
    Sendet eine neue DM: speichert Text verschlüsselt, IDs im Klartext.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))

    doc = {
        "date": msg.date,
        "text": encrypt_field(msg.text),  # verschlüsseln
        "senderId": my_id,                # Klartext
        "receiverId": partner_id,         # Klartext
        "read": False,
    }
    result = dm_collection.insert_one(doc)

    return {
        "_id":     str(result.inserted_id),
        "date":    msg.date,
        "senderId": my_id,                # Klartext
        "text":     msg.text,             # Klartext im Response
        "read":     False,
    }


@router.patch("/{partner_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_dm_read(
        partner_id: str,
        current_user: dict = Depends(get_current_patient),
):
    """
    Markiert alle ungelesenen Nachrichten von partner_id→User als gelesen.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))
    dm_collection.update_many(
        {
            "senderId":   partner_id,
            "receiverId": my_id,
            "read": False
        },
        {"$set": {"read": True}}
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/partners", response_model=List[PartnerWithUnread])
def get_chat_partners(current_user: dict = Depends(get_current_patient)):
    """
    Liefert alle Chat-Partner des eingeloggten Users inkl. Profil und Unread-Count.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))

    # alle Dokumente, in denen ich Sender oder Empfänger bin
    cursor = dm_collection.find({
        "$or": [
            {"senderId":   my_id},
            {"receiverId": my_id},
        ]
    })

    partner_ids: set = set()
    for doc in cursor:
        sender = doc["senderId"]       # Klartext
        receiver = doc["receiverId"]   # Klartext
        if sender != my_id:
            partner_ids.add(sender)
        if receiver != my_id:
            partner_ids.add(receiver)

    if not partner_ids:
        return []

    # Profile der Partner abrufen
    users = patients_collection.find({"med_id": {"$in": list(partner_ids)}})

    partners_with_unread: List[PartnerWithUnread] = []
    for u in users:
        pid = u["med_id"]  # Klartext
        firstname = decrypt_field(u["firstname"])
        lastname  = decrypt_field(u["lastname"])
        role      = u.get("role", "patient")

        unread = dm_collection.count_documents({
            "senderId":   pid,
            "receiverId": my_id,
            "read": False
        })

        partners_with_unread.append(
            PartnerWithUnread(
                firstname=firstname,
                lastname=lastname,
                med_id=pid,
                role=role,
                unreadCount=unread,
            )
        )

    return partners_with_unread
