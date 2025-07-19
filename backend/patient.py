from typing import List

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from backend.crypto_utils import decrypt_field
from backend.db import patients_collection
from backend.auth_utils import get_current_patient

router = APIRouter()


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
            firstname=decrypt_field(u["firstname"]),
            lastname=decrypt_field(u["lastname"]),
            med_id=u["med_id"],             # im Klartext
            role=u.get("role", "patient"),
        )
        for u in cursor
    ]


@router.get("/ping")
def ping():
    """
    Health check endpoint.
    """
    return {"msg": "pong"}


@router.get("/patient/me", response_model=PatientProfile)
def read_patient_me(current_user: dict = Depends(get_current_patient)):
    """
    Gibt das Profil des aktuell authentifizierten Nutzers zurück,
    inkl. der Rolle (default: patient).
    """
    return PatientProfile(
        firstname=decrypt_field(current_user["firstname"]),
        lastname=decrypt_field(current_user["lastname"]),
        med_id=current_user["med_id"],    # im Klartext
        role=current_user.get("role", "patient"),
    )


@router.get("/patient/all", response_model=List[PatientProfile])
def read_patient_all():
    """
    Listet alle Patienten (inkl. Rolle) im System auf.
    Falls in der DB keine Rolle hinterlegt ist, verwenden wir 'patient'.
    """
    patients = []
    for u in patients_collection.find():
        patients.append(PatientProfile(
            firstname=decrypt_field(u["firstname"]),
            lastname=decrypt_field(u["lastname"]),
            med_id=u["med_id"],
            role=u.get("role", "patient"),
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
