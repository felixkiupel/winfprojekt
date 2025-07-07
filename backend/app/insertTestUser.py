from pymongo import MongoClient
import bcrypt


MONGO_URI = "mongodb+srv://dbUser:dbUserPassword@medapp.tdtpszy.mongodb.net/MedApp?retryWrites=true&w=majority"
client = MongoClient(MONGO_URI)
db = client["med-app"]
collection = db["users"]

# Benutzerinformationen
plain_password = "1234"
hashed_password = bcrypt.hashpw(plain_password.encode("utf-8"), bcrypt.gensalt())

user = {
    "email": "test5@user.com",
    "password": hashed_password.decode("utf-8"),
    "firstname": "Test",
    "lastname": "User",
    "med_id": "2"
}

result = collection.insert_one(user)
print("Inserted ID:", result.inserted_id)

print("✅ Benutzer erfolgreich in MongoDB Atlas eingefügt!")

