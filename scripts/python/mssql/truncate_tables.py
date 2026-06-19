from db_connection import get_connection

conn = get_connection()
cursor = conn.cursor()

tables = [
    "OrderDetails",
    "OrdersTable",
    "Products",
    "Sellers",
    "Customers"
]

for table in tables:

    try:
        cursor.execute(f"DELETE FROM {table}")
        conn.commit()

        print(f"Cleared {table}")

    except Exception as e:
        print(e)

cursor.close()
conn.close()

print("All Tables Cleared")