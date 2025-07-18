# Type hint for returning a list of patients
from typing import List

# FastAPI router for modular route definitions and dependency injection
from fastapi import APIRouter, Depends

# Pydantic is used for data validation and response models
from pydantic import BaseModel, Field

# MongoDB users collection (holds all registered users)
from backend.db import patients_collection

# Function that extracts and verifies the current user from a JWT
from backend.auth_utils import get_current_patient


# Create a router object so we can modularize routes and include them in main.py
router = APIRouter()


# ---------- Pydantic Response Model ----------

class PatientProfile(BaseModel):
    """
    Dieses Schema definiert die Struktur der Patientendaten,
    inkl. der neuen Rolle. Standardmäßig ist role="patient".
    """
    firstname: str
    lastname: str
    med_id: str
    role: str = Field(
        default="patient",
        description="Rolle des Nutzers, z.B. 'patient' oder 'doctor'"
    )

def _read_by_role(role: str) -> List[PatientProfile]:
    """
    Hilfsfunktion, die alle Einträge mit der gegebenen Rolle
    aus der DB liest und als PatientProfile-Liste zurückgibt.
    """
    cursor = patients_collection.find({"role": role})
    return [
        PatientProfile(
            firstname=u["firstname"],
            lastname=u["lastname"],
            med_id=u["med_id"],
            role=u.get("role", "patient"),
        )
        for u in cursor
    ]

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
    Gibt das Profil des aktuell authentifizierten Nutzers zurück,
    inkl. der Rolle (default: patient).
    """
    return PatientProfile(
        firstname=current_user["firstname"],
        lastname=current_user["lastname"],
        med_id=current_user["med_id"],
        role=current_user.get("role", "patient"),
    )


@router.get("/patient/all", response_model=List[PatientProfile])
def read_patient_all():
    """
    Listet alle Patienten (inkl. Rolle) im System auf.
    Falls in der DB keine Rolle hinterlegt ist, verwenden wir 'patient'.
    """
    all_users_cursor = patients_collection.find()
    patients = []

    for user in all_users_cursor:
        patients.append(PatientProfile(
            firstname=user["firstname"],
            lastname=user["lastname"],
            med_id=user["med_id"],
            role=user.get("role", "patient"),
        ))

    return patients


@router.get("/patient/patients", response_model=List[PatientProfile])
def read_only_patients():
    """
    Liefert nur Nutzer:innen mit role='patient'.
    """
    return _read_by_role("patient")

@router.get("/patient/doctors", response_model=List[PatientProfile])
def read_only_doctors():
    """
    Liefert nur Nutzer:innen mit role='doctor'.
    """
    return _read_by_role("doctor")

# Example usage:
# curl -X GET http://127.0.0.1:8000/patient/all
