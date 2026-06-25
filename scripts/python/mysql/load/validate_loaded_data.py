from pathlib import Path
import mysql.connector

ROOT = Path(__file__).resolve().parents[4]

config = {}

config_file = ROOT / "config" / "windows" / "mysql.conf"

with open(config_file, encoding="utf-8") as f:
    for line in f:
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        if "=" in line:
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip()

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
