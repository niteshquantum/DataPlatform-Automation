from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.mysql.setup.db_connection import get_connection, config

try:

    conn = get_connection()
    cursor = conn.cursor()

    # =====================================
    # DATABASE
    # =====================================

    cursor.execute("SELECT DATABASE()")
    database = cursor.fetchone()[0]

    expected_database = config["MYSQL_DB"]

    if database.lower() != expected_database.lower():
        raise Exception(
            f"Expected database '{expected_database}' but connected to '{database}'"
        )

    # =====================================
    # PORT
    # =====================================

    cursor.execute("SELECT @@port")
    port = cursor.fetchone()[0]

    expected_port = int(config["MYSQL_PORT"])

    if port != expected_port:
        raise Exception(
            f"Expected port {expected_port} but connected to {port}"
        )

    # =====================================
    # VERSION
    # =====================================

    cursor.execute("SELECT VERSION()")
    version = cursor.fetchone()[0]

    expected_version = config["MYSQL_VERSION"]

    if not version.startswith(expected_version):
        raise Exception(
            f"Expected MySQL {expected_version} but found {version}"
        )

    # =====================================
    # LIQUIBASE TABLES
    # =====================================

    cursor.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_name IN (
                'DATABASECHANGELOG',
                'DATABASECHANGELOGLOCK'
          )
    """)

    liquibase_tables = {
        row[0].lower()
        for row in cursor.fetchall()
    }

    required_liquibase = {
        "databasechangelog",
        "databasechangeloglock"
    }

    missing = required_liquibase - liquibase_tables

    if missing:
        raise Exception(
            f"Missing Liquibase tables: {', '.join(sorted(missing))}"
        )

    # =====================================
    # USER TABLES
    # =====================================

    cursor.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
    """)

    tables = {
        row[0].lower()
        for row in cursor.fetchall()
    }

    tables -= {
        "databasechangelog",
        "databasechangeloglock"
    }

    if not tables:
        raise Exception("No application tables found.")

    # =====================================
    # SUCCESS
    # =====================================

    print()
    print("=" * 50)
    print("MYSQL DATABASE VALIDATION SUCCESS")
    print("=" * 50)
    print(f"Database : {database}")
    print(f"Port     : {port}")
    print(f"Version  : {version}")
    print()

    print("Application Tables:")

    for table in sorted(tables):
        print(f"[OK] {table}")

    print()
    print("Liquibase Tables:")

    for table in sorted(required_liquibase):
        print(f"[OK] {table}")

    print("=" * 50)

    cursor.close()
    conn.close()

except Exception as e:

    print()
    print("=" * 50)
    print("MYSQL DATABASE VALIDATION FAILED")
    print("=" * 50)
    print(e)
    print("=" * 50)

    exit(1)