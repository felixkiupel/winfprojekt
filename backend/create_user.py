from passlib.context import CryptContext
from db import users_collection

pwd_ctx = CryptContext(schemes=["bcrypt"])

def add_user(email: str, password: str,
             firstname: str = "", lastname: str = "", med_id: str = ""):
    hash_pw = pwd_ctx.hash(password)
    users_collection.insert_one({
        "email": email.lower().strip(),
        "password": hash_pw,
        "firstname": firstname,
        "lastname": lastname,
        "med_id": med_id,
    })
    print(f"✅ User {email} angelegt.")

# Beispielaufruf:
if __name__ == "__main__":
    add_user("neuer123@user.de", "supersecret", firstname="Neuer", lastname="User", med_id="3")
