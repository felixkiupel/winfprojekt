from pymongo import MongoClient

uri = "mongodb+srv://dbUser:dbUserPassword@medapp.tdtpszy.mongodb.net/MedApp?retryWrites=true&w=majority"
client = MongoClient(uri)
try:
    client.admin.command("ping")
    print("✅ Verbindung erfolgreich")
except Exception as e:
    print(f"❌ Fehler: {e}")
