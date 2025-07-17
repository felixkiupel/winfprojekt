from backend.db import community_collection
import logging
import sys

def create_special_community():
    """
    Legt einen vordefinierten, "speziellen" Community-Eintrag an.
    """
    special_community = {
        "title": "Spezieller Eintrag",
        "description": "Dies ist eine automatisch angelegte, besondere Community.",
        "avg_messages": 42
    }

    try:
        result = community_collection.insert_one(special_community)
    except Exception as e:
        logging.error(f"Fehler beim Anlegen der Community: {e}")
        sys.exit(1)

    if result.inserted_id:
        print(f"✔ Community erfolgreich angelegt (ID: {result.inserted_id})")
    else:
        logging.error("Community konnte nicht angelegt werden.")
        sys.exit(1)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    create_special_community()