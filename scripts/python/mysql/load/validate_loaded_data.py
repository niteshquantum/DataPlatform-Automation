from pathlib import Path
import sys
import mysql.connector

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config

config = load_database_config("mysql")

conn = mysql.connector.connect(
    host=config["MYSQL_HOST"],
    port=int(config["MYSQL_PORT"]),
    user=config["MYSQL_USER"],
    password=config["MYSQL_PASSWORD"],
    database=config["MYSQL_DB"]
)

cursor = conn.cursor()

cursor.execute("""
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
""")

tables = [row[0] for row in cursor.fetchall()]

system_tables = {
    "databasechangelog",
    "databasechangeloglock"
}

print()
print("=" * 50)
print("LOADED DATA SUMMARY")
print("=" * 50)

for table in sorted(tables):

    if table.lower() in system_tables:
        continue

    cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
    count = cursor.fetchone()[0]

    print(f"{table:<30} {count}")

cursor.close()
conn.close()

print("=" * 50)
print("DATA VALIDATION COMPLETED")
print("=" * 50)