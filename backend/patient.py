# Type hint for returning a list of patients
from typing import List

# FastAPI router for modular route definitions and dependency injection
from fastapi import APIRouter, Depends

# Pydantic is used for data validation and response models
from pydantic import BaseModel

# MongoDB users collection (holds all registered users)
from backend.db import patients_collection

# Function that extracts and verifies the current user from a JWT
from backend.auth_utils import get_current_patient


# Create a router object so we can modularize routes and include them in main.py
router = APIRouter()


# ---------- Pydantic Response Model ----------

class PatientProfile(BaseModel):
    """
    This schema defines the structure of patient profile data
    returned by the API. Used in GET responses.
    """
    firstname: str
    lastname: str
    med_id: str


# ---------- API Endpoints ----------

@router.get("/ping")
def ping():
    """
    Health check endpoint.

    Returns:
        Simple confirmation message. Used for testing
        if the backend is running and reachable.
    """
    return {"msg": "pong"}


@router.get("/patient/me", response_model=PatientProfile)
def read_patient_me(current_user: dict = Depends(get_current_patient)):
    """
    Returns the profile of the currently authenticated user (patient).

    Uses the JWT token to identify the user and pulls profile info
    from the MongoDB collection.

    Returns:
        A PatientProfile object containing:
        - firstname
        - lastname
        - med_id
    """
    return PatientProfile(
        firstname=current_user["firstname"],
        lastname=current_user["lastname"],
        med_id=current_user["med_id"],
    )


@router.get("/patient/all", response_model=List[PatientProfile])
def read_patient_all():
    """
    Returns a list of all patients in the system.

    This endpoint is unprotected (open to anyone) unless further restricted.
    It queries the database and converts each user document into a PatientProfile.

    Returns:
        A list of PatientProfile objects.
    """
    all_users_cursor = patients_collection.find()
    patients = []

    for user in all_users_cursor:
        patients.append(PatientProfile(
            firstname=user["firstname"],
            lastname=user["lastname"],
            med_id=user["med_id"],
        ))

    return patients




# Example usage:
# curl -X GET http://127.0.0.1:8000/patient/all
