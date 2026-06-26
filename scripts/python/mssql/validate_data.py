import json
from pathlib import Path
from db_connection import get_connection, config

try:

    conn = get_connection()
    cursor = conn.cursor()

    # Database name
    cursor.execute("SELECT DB_NAME()")
    result = cursor.fetchone()

    if result is None:
        raise Exception("Unable to fetch current database name")

    database = result[0]
    expected_database = config["MSSQL_DB"]

    if database.lower() != expected_database.lower():
        raise Exception(
            f"Expected database '{expected_database}' but connected to '{database}'"
        )

    # Port
    port = config["MSSQL_PORT"]

    # Version
    cursor.execute("SELECT @@VERSION")
    result = cursor.fetchone()

    if result is None:
        raise Exception("Unable to fetch SQL Server version")

    version = result[0]

    schema_file = (
        Path(__file__).resolve().parents[3]
        / "metadata"
        / "mssql"
        / "schema_registry.json"
    )

    with open(schema_file, "r", encoding="utf-8") as f:
        schema_registry = json.load(f)

    validated_tables = set(schema_registry.keys())

    if not validated_tables:
        raise Exception("No user tables found in schema_registry.json")

    print()
    print("=" * 50)
    print("MsSQL VALIDATION SUCCESS")
    print("=" * 50)
    print(f"Database : {database}")
    print(f"Port     : {port}")
    print(f"Version  : {version[:80]}...")
    print()

    print("Tables Validated:")

    for table in sorted(validated_tables):

        cursor.execute(
            """
            SELECT COUNT(*)
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = 'dbo'
            AND TABLE_NAME = ?
            """,
            (table,)
        )

        result = cursor.fetchone()

        if result is None or result[0] == 0:
            print(f"[SKIPPED] {table} : table does not exist")
            continue

        cursor.execute(f"SELECT COUNT(*) FROM [{table}]")
        count = cursor.fetchone()[0]

        print(f"[OK] {table:<50} {count} rows")

    print("=" * 50)

    cursor.close()
    conn.close()

except Exception as e:

    import traceback

    print()
    print("=" * 50)
    print("MsSQL VALIDATION FAILED")
    print("=" * 50)
    print(traceback.format_exc())
    print("=" * 50)

    exit(1)
