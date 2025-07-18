"""
Dieses Skript legt beispielhaft 3 Ärzt:innen und 3 Patient:innen an.
Jeder Nutzer bekommt das Passwort "111111" (gehasht) und eine E-Mail-Adresse.
"""

from backend.db import patients_collection
from backend.auth_utils import pwd_context

def seed_users():
    # IDs, die wir neu seeden wollen
    med_ids = ["D001", "D002", "D003", "P001", "P002", "P003"]

    # Alte Test-Einträge mit denselben med_id entfernen
    patients_collection.delete_many({"med_id": {"$in": med_ids}})

    # Passwort und Hash einmal erzeugen
    raw_pw = "111111"
    hashed_pw = pwd_context.hash(raw_pw)

    # Definiere alle Users mit E-Mail, gehashtem Passwort, Rolle etc.
    users = [
        # Ärzt:innen
        {
            "email": "anna.schmidt@hospital.com",
            "password": hashed_pw,
            "firstname": "Dr. Anna",
            "lastname": "Schmidt",
            "med_id": "D001",
            "role": "doctor",
        },
        {
            "email": "peter.weber@hospital.com",
            "password": hashed_pw,
            "firstname": "Dr. Peter",
            "lastname": "Weber",
            "med_id": "D002",
            "role": "doctor",
        },
        {
            "email": "laura.fischer@hospital.com",
            "password": hashed_pw,
            "firstname": "Dr. Laura",
            "lastname": "Fischer",
            "med_id": "D003",
            "role": "doctor",
        },
        # Patient:innen
        {
            "email": "max.mueller@example.com",
            "password": hashed_pw,
            "firstname": "Max",
            "lastname": "Müller",
            "med_id": "P001",
            "role": "patient",
        },
        {
            "email": "erika.mustermann@example.com",
            "password": hashed_pw,
            "firstname": "Erika",
            "lastname": "Mustermann",
            "med_id": "P002",
            "role": "patient",
        },
        {
            "email": "hans.schneider@example.com",
            "password": hashed_pw,
            "firstname": "Hans",
            "lastname": "Schneider",
            "med_id": "P003",
            "role": "patient",
        },
    ]

    result = patients_collection.insert_many(users)
    print(f"Seeded {len(result.inserted_ids)} users:")
    for _id, user in zip(result.inserted_ids, users):
        print(f" • {_id} → {user['email']} ({user['role']})")

if __name__ == "__main__":
    seed_users()
