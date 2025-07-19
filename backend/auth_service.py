from dotenv import load_dotenv

from fastapi import HTTPException, status, Depends, APIRouter
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, EmailStr

from backend.db import patients_collection
from backend import patient
from backend.auth_utils import (
    verify_password,
    create_access_token,
    pwd_context,
    get_user_from_token
)
from backend.crypto_utils import encrypt_field, decrypt_field

load_dotenv()

router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")


class LoginRequest(BaseModel):
    email: str
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    password_confirm: str
    firstname: str
    lastname: str
    med_id: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class PatientProfile(BaseModel):
    firstname: str
    lastname: str
    med_id: str


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest):
    user = patients_collection.find_one({"email": data.email.lower().strip()})
    if not user or not verify_password(data.password, user["password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Ungültige Anmeldedaten")
    token = create_access_token(str(user["_id"]))
    return {"access_token": token, "token_type": "bearer"}


@router.post("/register", response_model=TokenResponse)
def register(data: RegisterRequest):
    email = data.email.lower().strip()
    if data.password != data.password_confirm:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Passwörter stimmen nicht überein")
    if patients_collection.find_one({"email": email}):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="E-Mail bereits registriert")

    hashed_pw = pwd_context.hash(data.password)
    enc_firstname = encrypt_field(data.firstname.strip())
    enc_lastname = encrypt_field(data.lastname.strip())
    med_id_plain = data.med_id.strip()          # im Klartext

    result = patients_collection.insert_one({
        "email": email,
        "password": hashed_pw,
        "firstname": enc_firstname,
        "lastname": enc_lastname,
        "med_id": med_id_plain,                # im Klartext
        "role": "patient",
    })

    token = create_access_token(str(result.inserted_id))
    return {"access_token": token, "token_type": "bearer"}


@router.get("/profile", response_model=PatientProfile)
def get_profile(token: str = Depends(oauth2_scheme)):
    user_id = get_user_from_token(token)
    user = patients_collection.find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User nicht gefunden")
    return PatientProfile(
        firstname=decrypt_field(user["firstname"]),
        lastname=decrypt_field(user["lastname"]),
        med_id=user["med_id"]                   # im Klartext
    )


@router.get("/ping")
def ping():
    return {"msg": "pong"}


# die Patienten-Routen mit einbinden
router.include_router(patient.router)
