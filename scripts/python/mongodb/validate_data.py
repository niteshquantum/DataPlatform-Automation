import json
from pathlib import Path
from db_connection import get_db

db = get_db()

all_valid = True

all_valid = True

print("===================================")
print("MongoDB Data Validation")
print("===================================")

schema_file = (
    Path(__file__).resolve().parents[3]
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

for collection in collections:


    count = db[collection].count_documents({})

    if count == 0:

        print(f"[ERROR] {collection} contains no records")
        all_valid = False

    else:

        print(f"{collection}: {count} records found.")

print("===================================")

if not all_valid:
    raise Exception("MongoDB Data Validation Failed")

print("MongoDB Data Validation Successful")
print("===================================")
