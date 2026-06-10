from db_connection import get_connection

conn = get_connection()
cursor = conn.cursor()

cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

cursor.execute("SHOW TABLES")

tables = [row[0] for row in cursor.fetchall()]

skip_tables = [
    "databasechangelog",
    "databasechangeloglock"
]

for table in tables:

    if table.lower() in skip_tables:
        continue

    cursor.execute(f"TRUNCATE TABLE {table}")

    print(f"Truncated {table}")

cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

conn.commit()

cursor.close()
conn.close()

print("All Tables Truncated Successfully")