import os
from pymongo import MongoClient
from dotenv import load_dotenv

# .env-Datei laden
load_dotenv()

# MongoDB URI aus .env
MONGO_URI = os.getenv("MONGO_URI")

# Verbindung zur Datenbank
client = MongoClient(MONGO_URI)
db = client["med-app"]  # kannst du beliebig benennen
users_collection = db["users"]
