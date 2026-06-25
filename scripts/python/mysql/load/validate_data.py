import json
from pathlib import Path
from scripts.python.mysql.setup.db_connection import get_connection, config

try:

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT DATABASE()")
    database = cursor.fetchone()[0]

    expected_database = config["MYSQL_DB"]

    if database.lower() != expected_database.lower():
        raise Exception(
            f"Expected database '{expected_database}' but connected to '{database}'"
        )

    cursor.execute("SELECT @@port")
    port = cursor.fetchone()[0]

    cursor.execute("SELECT VERSION()")
    version = cursor.fetchone()[0]

    schema_file = (
    Path(__file__).resolve().parents[4]
    / "metadata"
    / "mysql"
    / "schema_registry.json"
    )

    cursor.execute("""

        SELECT table_name

        FROM information_schema.tables

        WHERE table_schema = DATABASE()

    """)
    
    existing_tables = {

        row[0].lower()

        for row in cursor.fetchall()

    }
    
    # Ignore Liquibase internal tables

    system_tables = {

        "databasechangelog",

        "databasechangeloglock"

    }
    
    validated_tables = existing_tables - system_tables
    
    if not validated_tables:

        raise Exception("No user tables found")
    

    print()
    print("=" * 50)
    print("MYSQL VALIDATION SUCCESS")
    print("=" * 50)
    print(f"Database : {database}")
    print(f"Port     : {port}")
    print(f"Version  : {version}")

    print()
    print("Tables Validated:")

    for table in sorted(validated_tables):

        cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
        count = cursor.fetchone()[0]

        print(f"[OK] {table} : {count} rows")

    print("=" * 50)

    cursor.close()
    conn.close()

except Exception as e:

    print()
    print("=" * 50)
    print("MYSQL VALIDATION FAILED")
    print("=" * 50)
    print(e)
    print("=" * 50)

    exit(1)