import json
from pathlib import Path

from db_connection import get_db

db = get_db()

print()
print("=" * 50)
print("MONGODB VALIDATION")
print("=" * 50)

schema_file = (
    Path(__file__).resolve().parents[4]
    / "metadata"
    / "mongodb"
    / "schema_registry.json"
)

with open(schema_file, "r", encoding="utf-8") as f:
    schema_registry = json.load(f)

collections = [
    collection.lower()
    for collection in schema_registry.keys()
]

if not collections:
    raise Exception("No collections found in schema registry")

print()

for collection in collections:

    count = db[collection].count_documents({})

    print(f"[OK] {collection} : {count} documents")

print()
print("=" * 50)
print("MONGODB VALIDATION SUCCESS")
print("=" * 50)






