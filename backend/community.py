from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from backend.db import community_collection
from backend.auth_utils import get_current_user

router = APIRouter(
    prefix="/community",
    tags=["community"],
)

# Pydantic-Modell für eine Community
class Community(BaseModel):
    title: str
    description: str
    avg_messages: int

# --- Mapper-Funktionen ----------------------------------------------------

def _doc_to_model(doc: dict) -> Community:
    # Wir rechnen hier mit docs ohne _id-Feld, deshalb direkt entpacken
    return Community(**doc)

def _model_to_doc(model: Community) -> dict:
    return model.dict()

# --- Data-Access-Funktionen ----------------------------------------------

def get_all_communities() -> List[Community]:
    cursor = community_collection.find({}, {"_id": False})
    return [_doc_to_model(doc) for doc in cursor]

def create_community_in_db(community: Community) -> Community:
    doc = _model_to_doc(community)
    result = community_collection.insert_one(doc)
    if not result.inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create community"
        )
    return community

# --- HTTP-Endpoints -------------------------------------------------------

@router.post(
    "/",
    response_model=Community,
    status_code=status.HTTP_201_CREATED
)
def create_community(
        community: Community,
        current_user = Depends(get_current_user)
):

    return create_community_in_db(community)

@router.get(
    "/",
    response_model=List[Community]
)
def list_communities():
    return get_all_communities()
