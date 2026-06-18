from db_connection import get_db

db = get_db()

# Collections to create
collections = [
    "customers",
    "sellers",
    "products",
    "orders",
    "orderdetails"
]

existing = db.list_collection_names()

for collection in collections:
    if collection not in existing:
        db.create_collection(collection)
        print(f"{collection} collection created.")
    else:
        print(f"{collection} collection already exists.")

print("Collection creation completed.")