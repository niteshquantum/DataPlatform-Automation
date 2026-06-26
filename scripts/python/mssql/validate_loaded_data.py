from pathlib import Path
import platform
from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

if platform.system() == "Windows":
    config_file = ROOT / "config" / "windows" / "mssql.conf"
else:
    config_file = ROOT / "config" / "ubuntu" / "mssql.conf"

config = {}

with open(config_file) as f:
    for line in f:
        if "=" in line:
            k, v = line.strip().split("=", 1)
            config[k] = v

conn = get_connection()

cursor = conn.cursor()

cursor.execute("""
    SELECT TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'dbo'
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

    cursor.execute(f"SELECT COUNT(*) FROM [{table}]")
    count = cursor.fetchone()[0]

    print(f"{table:<40} {count}")

cursor.close()
conn.close()

print("=" * 50)
print("DATA VALIDATION COMPLETED")
print("=" * 50)
