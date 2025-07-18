from dotenv import load_dotenv
load_dotenv()

# bestehende DB-Verbindung nutzen
from backend.db import community_collection

def seed_communities():
    communities = [
        {
            "title": "Flutter Enthusiasts",
            "description": "A community for Flutter developers to exchange tips and best practices.",
            "avg_messages": 0
        },
        {
            "title": "Open Source Contributors",
            "description": "Join forces on open-source projects and share your code.",
            "avg_messages": 0
        },
        {
            "title": "Tech Talk",
            "description": "Discuss the latest trends in technology and innovation.",
            "avg_messages": 0
        },
        {
            "title": "test",
            "description": "xxx",
            "avg_messages": 100
        },
    ]

    result = community_collection.insert_many(communities)
    print(f"✔️  Inserted {len(result.inserted_ids)} communities:")
    for cid in result.inserted_ids:
        print(f"   • {cid}")

if __name__ == "__main__":
    seed_communities()
