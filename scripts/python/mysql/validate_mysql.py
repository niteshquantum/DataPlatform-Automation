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

    required_tables = {
        "customers",
        "sellers",
        "products",
        "orderstable",
        "orderdetails",
        "databasechangelog",
        "databasechangeloglock"
    }

    cursor.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
    """)

    existing_tables = {row[0].lower() for row in cursor.fetchall()}

    missing_tables = required_tables - existing_tables

    if missing_tables:
        raise Exception(
            f"Missing tables: {', '.join(sorted(missing_tables))}"
        )

    print()
    print("=" * 50)
    print("MYSQL VALIDATION SUCCESS")
    print("=" * 50)
    print(f"Database : {database}")
    print(f"Port     : {port}")
    print(f"Version  : {version}")
    print()
    print("Tables Validated:")

    for table in sorted(required_tables):
        print(f"[OK] {table}")

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