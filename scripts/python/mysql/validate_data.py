import json
from pathlib import Path
from db_connection import get_connection, config

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
        Path(__file__).resolve().parents[3]
        / "metadata"
        / "mysql"
        / "schema_registry.json"
    )

    # Load schema registry
    with open(schema_file, "r", encoding="utf-8") as f:
        schema_registry = json.load(f)

    validated_tables = set(schema_registry.keys())

    if not validated_tables:
        raise Exception("No user tables found in schema_registry.json")

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

        cursor.execute(
            """
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = DATABASE()
            AND table_name = %s
            """,
            (table,)
        )

        if cursor.fetchone()[0] == 0:
            print(f"[SKIPPED] {table} : table does not exist")
            continue

        print("validate_tables:", table)

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
