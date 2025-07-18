from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from backend.db import doctors_collection
from backend.auth_utils import get_current_patient

router = APIRouter()

# ---------- Pydantic Response Model ----------
class DoctorProfile(BaseModel):
    """
    Schema für Arzt-Profile
    """
    firstname: str
    lastname: str
    med_id: str

# ---------- API Endpoints ----------
@router.get("/doctor/me", response_model=DoctorProfile)
def read_doctor_me(current_user: dict = Depends(get_current_patient)):
    """
    Profil des aktuell angemeldeten Arztes
    """
    return DoctorProfile(
        firstname=current_user["firstname"],
        lastname=current_user["lastname"],
        med_id=current_user["med_id"],
    )

@router.get("/doctor/all", response_model=List[DoctorProfile])
def read_doctor_all():
    """
    Liste aller registrierten Ärzte
    """
    docs = []
    for doc in doctors_collection.find():
        docs.append(DoctorProfile(
            firstname=doc.get("firstname"),
            lastname=doc.get("lastname"),
            med_id=doc.get("med_id"),
        ))
    return docs

