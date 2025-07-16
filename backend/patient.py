from typing import List
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from backend.db import users_collection
from backend.auth_utils import get_current_user

router = APIRouter()


class PatientProfile(BaseModel):
    firstname: str
    lastname: str
    med_id: str


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
    patients = []

    for user in all_users_cursor:
        patients.append(PatientProfile(
            firstname=user["firstname"],
            lastname=user["lastname"],
            med_id=user["med_id"],
        ))

    return patients


#curl -X GET  http://127.0.0.1:8000/patient/all
