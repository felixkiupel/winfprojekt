from fastapi import APIRouter, Depends, HTTPException, status, Response
from pydantic import BaseModel, Field
from typing import List
from datetime import datetime

from backend.db import dm_collection, patients_collection
from backend.auth_utils import get_current_patient
from backend.patient import PatientProfile

router = APIRouter(
    prefix="/dm",
    tags=["direct-message"],
)

# Eingangsmodell für Chat-Nachrichten
class ChatMessageIn(BaseModel):
    date: datetime
    text: str

# Ausgangsmodell: wandelt _id → id um und liefert read-Status
class ChatMessageOut(BaseModel):
    id: str = Field(..., alias="_id")
    date: datetime
    senderId: str
    text: str
    read: bool

# Neues Modell für Partner mit Ungelesen-Count
class PartnerWithUnread(PatientProfile):
    unreadCount: int = Field(
        ..., description="Anzahl der ungelesenen Nachrichten von diesem Partner"
    )

@router.get("/{partner_id}/messages", response_model=List[ChatMessageOut])
def get_dm_messages(
        partner_id: str,
        current_user: dict = Depends(get_current_patient),
):
    """
    Liefert alle Nachrichten zwischen eingeloggtem User und partner_id,
    sortiert nach Datum aufsteigend, inklusive Read/Unread-Status.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))
    cursor = dm_collection.find(
        {
            "$or": [
                {"senderId": my_id, "receiverId": partner_id},
                {"senderId": partner_id, "receiverId": my_id},
            ]
        }
    ).sort("date", 1)

    out = []
    for doc in cursor:
        out.append({
            "_id": str(doc["_id"]),
            "date": doc["date"],
            "senderId": doc["senderId"],
            "text": doc["text"],
            "read": doc.get("read", False),
        })
    return out

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
    Sendet eine neue DM vom eingeloggten User an partner_id.
    Initial setzt der read-Status auf False.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))
    doc = {
        "date": msg.date,
        "text": msg.text,
        "senderId": my_id,
        "receiverId": partner_id,
        "read": False,
    }
    result = dm_collection.insert_one(doc)
    doc["_id"] = str(result.inserted_id)
    return doc

@router.patch("/{partner_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_dm_read(
        partner_id: str,
        current_user: dict = Depends(get_current_patient),
):
    """
    Markiert alle ungelesenen Nachrichten von partner_id → eingeloggter User als gelesen.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))
    dm_collection.update_many(
        {
            "senderId": partner_id,
            "receiverId": my_id,
            "read": False
        },
        {"$set": {"read": True}}
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.get("/partners", response_model=List[PartnerWithUnread])
def get_chat_partners(current_user: dict = Depends(get_current_patient)):
    """
    Liefert alle bisherigen Chat-Partner des eingeloggten Users zurück
    (jeweils nur einmal), inkl. firstname, lastname, med_id, role und Anzahl ungelesener Nachrichten.
    """
    my_id = current_user.get("med_id") or str(current_user.get("_id"))

    # 1) Alle DM-Dokumente, in denen der User Sender oder Empfänger ist
    cursor = dm_collection.find({
        "$or": [
            {"senderId": my_id},
            {"receiverId": my_id},
        ]
    })

    # 2) Einzigartige Partner-IDs sammeln
    partner_ids = set()
    for doc in cursor:
        if doc["senderId"] != my_id:
            partner_ids.add(doc["senderId"])
        if doc["receiverId"] != my_id:
            partner_ids.add(doc["receiverId"])

    if not partner_ids:
        return []

    # 3) Profildaten der Partner aus patients_collection laden
    users = list(patients_collection.find({"med_id": {"$in": list(partner_ids)}}))

    partners_with_unread: List[PartnerWithUnread] = []
    for u in users:
        pid = u["med_id"]
        # 4) Ungelesene Nachrichten von diesem Partner zählen
        unread = dm_collection.count_documents({
            "senderId": pid,
            "receiverId": my_id,
            "read": False
        })
        partners_with_unread.append(
            PartnerWithUnread(
                firstname=u["firstname"],
                lastname=u["lastname"],
                med_id=pid,
                role=u.get("role", "patient"),
                unreadCount=unread,
            )
        )

    return partners_with_unread
