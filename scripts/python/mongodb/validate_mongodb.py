from db_connection import get_db

db = get_db()

collections = [
    "customers",
    "sellers",
    "products",
    "orders",
    "orderdetails"
]

print("===================================")
print("MongoDB Validation")
print("===================================")

existing_collections = db.list_collection_names()

all_valid = True

for collection in collections:

    if collection not in existing_collections:

        print(f"[ERROR] Collection missing: {collection}")
        all_valid = False
        continue

    count = db[collection].count_documents({})

    print(f"{collection}: {count} documents")

print("===================================")

if all_valid:
    print("MongoDB validation successful.")
else:
    raise Exception("MongoDB validation failed.")