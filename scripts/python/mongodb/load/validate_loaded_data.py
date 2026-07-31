from pathlib import Path
import sys

from pymongo import MongoClient

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.mongodb.setup.config_loader import load_config

config = load_config()

client = MongoClient(
    host=config["MONGODB_HOST"],
    port=int(config["MONGODB_PORT"]),
    username=config["RBAC_ADMIN_USERNAME"],
    password=config["RBAC_ADMIN_PASSWORD"],
    authSource="admin",
)

db = client[config["MONGODB_DATABASE"]]

collections = db.list_collection_names()

print()
print("=" * 50)
print("LOADED DATA SUMMARY")
print("=" * 50)

if not collections:

    print("No collections found.")

else:

    for collection in sorted(collections):

        count = db[collection].count_documents({})

        print(f"{collection:<30} {count}")

print("=" * 50)
print("DATA VALIDATION COMPLETED")
print("=" * 50)

client.close()
