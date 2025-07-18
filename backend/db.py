# Import standard and third-party libraries
import os
from pymongo import MongoClient
from dotenv import load_dotenv

# ---------- Load Environment Variables ----------

# Loads variables from a .env file into the environment (e.g. MONGO_URI)
# This keeps sensitive info like credentials or DB URLs out of your codebase
load_dotenv()

# ---------- MongoDB Configuration ----------

# Read the MongoDB URI from the environment variables
# Example value in .env: MONGO_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net
MONGO_URI = os.getenv("MONGO_URI")

# ---------- Establish MongoDB Connection ----------

# Create a MongoDB client using the URI
# This client represents the connection to the database server
client = MongoClient(MONGO_URI)

# Access the specific database called "med-app"
db = client["med-app"]

# Access the "users" collection inside the "med-app" database
# This collection will store user documents (e.g. email, password, med_id, etc.)
patients_collection = db["patients"]
doctors_collection = db["doctors"]
# Access the "community" collection inside the "med-app" database
community_collection = db["community"]

com_messages_collection = db["com-messages"]
dm_collection = db["dm-messages"]

# Einmalig, verhindert doppelte titles:
community_collection.create_index("title", unique=True)

