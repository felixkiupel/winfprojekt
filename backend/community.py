# backend/community.py

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from backend.db import community_collection
from backend.auth_utils import get_current_user

router = APIRouter(
    prefix="/community",
    tags=["community"],
)

class Community(BaseModel):
    title: str
    description: str
    avg_messages: int

@router.post(
    "/",
    response_model=Community,
    status_code=status.HTTP_201_CREATED
)
def create_community(
        community: Community,
        current_user = Depends(get_current_user)
):
    """
    Create a new community with a title, description, and average message count.
    """
    insert_result = community_collection.insert_one(community.dict())
    if not insert_result.inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create community"
        )
    return community

@router.get(
    "/",
    response_model=List[Community]
)
def list_communities():
    """
    Retrieve a list of all communities.
    """
    cursor = community_collection.find({}, {"_id": False})
    return [Community(**c) for c in cursor]
