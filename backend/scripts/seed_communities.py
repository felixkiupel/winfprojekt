from dotenv import load_dotenv
load_dotenv()

# bestehende DB-Verbindung nutzen
from backend.db import community_collection

def seed_medical_communities():
    communities = [
        {
            "title": "Aboriginal Health Forum",
            "description": "A space for Aboriginal health professionals and patients to discuss best practices, resources, and community wellness.",
            "avg_messages": 64
        },
        {
            "title": "First Nations Mental Health",
            "description": "Dedicated to sharing culturally appropriate mental health strategies and support for First Nations communities.",
            "avg_messages": 48
        },
        {
            "title": "Torres Strait Medical Exchange",
            "description": "Connecting healthcare workers across the Torres Strait Islands to coordinate medical outreach and telehealth services.",
            "avg_messages": 52
        },
        {
            "title": "Indigenous Nutrition Network",
            "description": "Collaborating on nutrition programs and traditional food knowledge to improve health outcomes.",
            "avg_messages": 37
        },
    ]

    result = community_collection.insert_many(communities)
    print(f"✔️  Inserted {len(result.inserted_ids)} medical communities:")
    for cid in result.inserted_ids:
        print(f"   • {cid}")

if __name__ == "__main__":
    seed_medical_communities()
