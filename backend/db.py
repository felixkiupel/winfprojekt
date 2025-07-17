# Import standard and third-party libraries
import os
from pymongo import MongoClient
from dotenv import load_dotenv

# ---------- Load Environment Variables ----------

# Loads variables from a .env file into the environment (e.g. MONGO_URI)
# This keeps sensitive info like credentials or DB URLs out of your codebase
load_dotenv()

# ---------- MongoDB Configuration ----------

# Read the MongoDB URI from the environment variables
# Example value in .env: MONGO_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net
MONGO_URI = os.getenv("MONGO_URI")

# ---------- Establish MongoDB Connection ----------

# Create a MongoDB client using the URI
# This client represents the connection to the database server
client = MongoClient(MONGO_URI)

# Access the specific database called "med-app"
db = client["med-app"]

# Access the "users" collection inside the "med-app" database
# This collection will store user documents (e.g. email, password, med_id, etc.)
users_collection = db["users"]
# Access the "community" collection inside the "med-app" database
community_collection = db["community"]

messages_collection = db["messages"]


# === New file: backend/community.py ===
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from backend.db import community_collection
from backend.auth_utils import get_current_user

# Define a router for community-related endpoints
router = APIRouter(
    prefix="/community",
    tags=["community"],
)

# Pydantic model for a Community document
class Community(BaseModel):
    title: str
    description: str
    avg_messages: int

@router.post("/", response_model=Community, status_code=status.HTTP_201_CREATED)
def create_community(
        community: Community,
        current_user = Depends(get_current_user)
):
    """
    Create a new community with a title, description, and average message count.
    """
    # Optional: enforce permissions or user roles here
    insert_result = community_collection.insert_one(community.dict())
    if not insert_result.inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create community"
        )
    return community

@router.get("/", response_model=List[Community])
def list_communities():
    """
    Retrieve a list of all communities.
    """
    cursor = community_collection.find({}, {"_id": False})
    return [Community(**c) for c in cursor]


# === Changes to existing file: backend/auth_service.py ===
# 1. Import the community router at the top of the file (along with patient):
#    from backend import community

# 2. Include the community router after including patient routes:
#    app.include_router(community.router)
