from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from pymongo.errors import DuplicateKeyError

from backend.db import community_collection, patients_collection
from backend.auth_utils import get_current_patient


router = APIRouter(
    prefix="/communitys",
    tags=["community"],
)


# ─── Pydantic-Modelle ───────────────────────────────────────────────

class CommunityCreate(BaseModel):
    name: str
    description: str

class CommunitySummary(BaseModel):
    name: str
    description: str

class CommunitiesUpdate(BaseModel):
    communities: List[str]


# ─── Endpunkt: Alle Communities ─────────────────────────────────────

@router.get(
    "/all",
    response_model=List[CommunitySummary],
    status_code=status.HTTP_200_OK
)
def list_all_communities():
    """
    GET /communitys/all
    Liefert eine Liste aller Communities als { name, description }.
    """
    docs = community_collection.find({})
    return [
        CommunitySummary(name=doc["title"], description=doc["description"])
        for doc in docs
    ]


# ─── Endpunkt: Neue Community anlegen ────────────────────────────────

@router.post(
    "/",
    response_model=CommunitySummary,
    status_code=status.HTTP_201_CREATED
)
def create_community(
        comm: CommunityCreate,
        current_user=Depends(get_current_patient)
):
    """
    POST /communitys/
    Legt eine neue Community an. Nur für eingeloggte User.
    Verhindert Duplikate via Unique-Index und fängt den Fehler ab.
    """
    doc = {
        "title": comm.name,
        "description": comm.description,
        "avg_messages": 0
    }
    try:
        community_collection.insert_one(doc)
    except DuplicateKeyError:
        # Wenn schon vorhanden, gib 409 Conflict
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Community '{comm.name}' existiert bereits."
        )
    return CommunitySummary(name=comm.name, description=comm.description)


# ─── Endpunkt: Meine Communities auslesen ────────────────────────────

@router.get(
    "/me",
    response_model=List[str],
    status_code=status.HTTP_200_OK
)
def read_my_communities(
        current_user: dict = Depends(get_current_patient)
):
    """
    GET /communitys/me
    Gibt direkt ein JSON-Array der Community-Namen zurück,
    so wie Flutter es erwartet:
      ["Community A", "Community B", ...]
    """
    return current_user.get("communities", [])


# ─── Endpunkt: Meine Communities setzen ──────────────────────────────

@router.put(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT
)
def set_my_communities(
        selection: CommunitiesUpdate,
        current_user: dict = Depends(get_current_patient)
):
    """
    PUT /communitys/me
    Erwartet { "communities": ["A","B",…] } und speichert
    diese Liste im eingeloggten User-Dokument.
    Liefert 204 No Content.
    """
    user_id = current_user["_id"]
    result = patients_collection.update_one(
        {"_id": user_id},
        {"$set": {"communities": selection.communities}}
    )
    if result.matched_count != 1:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not update communities for user"
        )
    # 204 → kein Body
