from db_connection import get_db

db = get_db()

collections = [
    "customers",
    "sellers",
    "products",
    "orders",
    "orderdetails"
]

all_valid = True

print("===================================")
print("MongoDB Data Validation")
print("===================================")

for collection in collections:

    if collection not in db.list_collection_names():

        print(f"[ERROR] {collection} collection missing")
        all_valid = False
        continue

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