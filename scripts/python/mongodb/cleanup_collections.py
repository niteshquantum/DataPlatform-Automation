from db_connection import get_db

db = get_db()

collections = [
    "customers",
    "sellers",
    "products",
    "orders",
    "orderdetails"
]

for collection in collections:
    db[collection].delete_many({})
    print(f"{collection} collection cleaned.")

print("MongoDB cleanup completed.")