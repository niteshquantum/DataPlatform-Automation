from db_connection import get_db

try:

    db = get_db()

    print("Connected Successfully")

    print("Database :", db.name)

except Exception as e:

    print("Connection Failed")

    print(e)