# backend/patient.py

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from backend.db import users_collection, community_collection
from backend.auth_utils import get_current_user
from bson import ObjectId

router = APIRouter()

# ---------- Pydantic Models ----------

class PatientProfile(BaseModel):
    """
    Struktur der Patientendaten, die von /patient/me zurückgegeben werden.
    """
    firstname: str
    lastname: str
    med_id: str

class CommunityJoinRequest(BaseModel):
    """
    Schema für die Anfrage, wenn sich ein Patient einer Community anschließt.
    """
    title: str

class CommunitiesResponse(BaseModel):
    """
    Struktur der Antwort, die die Liste der Communities enthält,
    denen der Patient aktuell angehört.
    """
    communities: List[str]


# ---------- Endpoints ----------

@router.get("/ping")
def ping():
    return {"msg": "pong"}


@router.get("/patient/me", response_model=PatientProfile)
def read_patient_me(current_user: dict = Depends(get_current_user)):
    return PatientProfile(
        firstname=current_user["firstname"],
        lastname=current_user["lastname"],
        med_id=current_user["med_id"],
    )


@router.get("/patient/all", response_model=List[PatientProfile])
def read_patient_all():
    all_users_cursor = users_collection.find()
    return [
        PatientProfile(
            firstname=user["firstname"],
            lastname=user["lastname"],
            med_id=user["med_id"],
        )
        for user in all_users_cursor
    ]


@router.put(
    "/patient/me/communities",
    response_model=CommunitiesResponse,
    status_code=status.HTTP_200_OK
)
def join_community(
        req: CommunityJoinRequest,
        current_user: dict = Depends(get_current_user)
):
    """
    Fügt den aktuell eingeloggten Patient zu einer bestehenden Community hinzu.
    - req.title: der Title der Community
    """
    # Sicherstellen, dass die Community existiert
    community = community_collection.find_one({"title": req.title})
    if not community:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Community '{req.title}' nicht gefunden"
        )

    user_id = current_user["_id"]
    # Speichere oder erweitere das Array "communities" im User-Dokument
    users_collection.update_one(
        {"_id": ObjectId(user_id)},
        {"$addToSet": {"communities": req.title}}
    )

    # Hole die aktualisierten Daten
    updated_user = users_collection.find_one({"_id": ObjectId(user_id)})
    return CommunitiesResponse(
        communities=updated_user.get("communities", [])
    )
