from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

from backend.db import com_messages_collection
from backend.auth_utils import get_current_patient

router = APIRouter()

# Pydantic-Schemas
class MessageIn(BaseModel):
    date: datetime
    community: str
    title: str
    message: str

class MessageOut(BaseModel):
    id: str = Field(..., alias="_id")
    date: datetime
    community: str
    title: str
    message: str

# Endpoint: Loggen einer Nachricht
@router.put(
    "/com_messages",
    status_code=status.HTTP_201_CREATED,
    response_model=MessageOut,
)
async def log_message(msg: MessageIn):
    """
    Loggt eine neue Nachricht (PUT /com_messages).
    Body: { date, community, title, message }
    """
    doc = msg.dict()
    result = com_messages_collection.insert_one(doc)
    # Rückgabe: das frisch erzeugte Document mit String-ID
    doc["_id"] = str(result.inserted_id)
    return doc

# Endpoint: Alle Nachrichten (global)
@router.get(
    "/com_messages",
    response_model=List[MessageOut],
    status_code=status.HTTP_200_OK
)
async def get_all_messages():
    """
    Liefert alle geloggten Nachrichten, sortiert nach Datum absteigend.
    """
    cursor = com_messages_collection.find().sort("date", -1)
    out: List[dict] = []
    for doc in cursor:
        doc["_id"] = str(doc["_id"])
        out.append(doc)
    return out

# Endpoint: Community-spezifische Nachrichten
@router.get(
    "/messages",
    response_model=List[MessageOut],
    status_code=status.HTTP_200_OK
)
async def get_community_messages(
        communities: Optional[str] = Query(
            None,
            description="Kommagetrennte Community-Namen, z.B. 'A,B,C'"
        ),
        current_user: dict = Depends(get_current_patient)
):
    """
    Liefert alle Nachrichten der Communities, in denen der eingeloggte User ist.
    Query-Parameter: ?communities=A,B,C
    """
    if not communities:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Parameter 'communities' fehlt."
        )
    wanted = communities.split(",")
    cursor = com_messages_collection.find(
        {"community": {"$in": wanted}}
    ).sort("date", -1)
    out: List[dict] = []
    for doc in cursor:
        doc["_id"] = str(doc["_id"])
        out.append(doc)
    return out
