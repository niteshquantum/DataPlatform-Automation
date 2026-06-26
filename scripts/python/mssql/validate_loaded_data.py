from pathlib import Path
import platform
import mssql.connector

ROOT = Path(__file__).resolve().parents[3]

if platform.system() == "Windows":
    config_file = ROOT / "config" /"windows"/ "mssql.conf"
else:
    config_file = ROOT / "config" / "ubuntu" / "mssql.config"

config = {}

with open(config_file) as f:
    for line in f:
        if "=" in line:
            k, v = line.strip().split("=", 1)
            config[k] = v

conn = mssql.connector.connect(
    host=config["MSSQL_HOST"],
    port=int(config["MSSQL_PORT"]),
    user=config["MSSQL_USER"],
    password=config["MSSQL_PASSWORD"],
    database=config["MSSQL_DB"]
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
