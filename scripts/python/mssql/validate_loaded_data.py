from db_connection import get_connection

conn = get_connection()
cursor = conn.cursor()

tables = {
    "Customers": "Customers",
    "Sellers": "Sellers",
    "Products": "Products",
    "OrdersTable": "Orders",
    "OrderDetails": "OrderDetails"
}

print()
print("=" * 50)
print("LOADED DATA SUMMARY")
print("=" * 50)

for table, display_name in tables.items():

    cursor.execute(f"SELECT COUNT(*) FROM {table}")

    count = cursor.fetchone()[0]

    print(f"{display_name:<15} {count}")

cursor.close()
conn.close()

print("=" * 50)
print("DATA VALIDATION COMPLETED")
print("=" * 50)