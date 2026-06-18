from pathlib import Path
import mysql.connector

ROOT = Path(__file__).resolve().parents[3]

config = {}

with open(ROOT / "config" / "mysql.conf") as f:
    for line in f:
        if "=" in line:
            k, v = line.strip().split("=", 1)
            config[k] = v

conn = mysql.connector.connect(
    host=config["MYSQL_HOST"],
    port=int(config["MYSQL_PORT"]),
    user=config["MYSQL_USER"],
    password=config["MYSQL_PASSWORD"],
    database=config["MYSQL_DB"]
)

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