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
print("MongoDB Data Validation")
print("===================================")

for collection in collections:

    if collection in db.list_collection_names():

        count = db[collection].count_documents({})

        if count > 0:
            print(f"{collection}: {count} records found.")
        else:
            print(f"{collection}: Collection exists but contains no records.")

    else:
        print(f"{collection}: Collection does not exist.")

print("===================================")
print("Validation completed.")
print("===================================")