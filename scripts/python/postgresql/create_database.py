import sys
from db_connection import load_config
import psycopg2


def create_database():

    config = load_config()

    db_name = config.get("POSTGRESQL_DATABASE", "DataManagementDB")
    user    = config.get("POSTGRESQL_ADMIN_USER", "postgres")
    host    = config.get("POSTGRESQL_HOST", "localhost")
    port    = config.get("POSTGRESQL_PORT", "5432")
    password = config.get("POSTGRESQL_ADMIN_PASSWORD", "")

    print("=" * 60)
    print("CREATE DATABASE")
    print("=" * 60)
    print(f"Target Database : {db_name}")

    # Connect to postgres (maintenance DB)
    conn = psycopg2.connect(
        host=host,
        port=port,
        database="postgres",
        user=user,
        password=password
    )

    conn.autocommit = True
    cursor = conn.cursor()

    # Check if database already exists
    cursor.execute(
        "SELECT COUNT(*) FROM pg_database WHERE datname = %s",
        (db_name,)
    )

    exists = cursor.fetchone()[0]

    if exists:
        print(f"Database already exists : {db_name}")
        print("Reusing existing database")
    else:
        cursor.execute(f'CREATE DATABASE "{db_name}"')
        print(f"Database created : {db_name}")

    cursor.close()
    conn.close()

    print("Create database completed successfully")


if __name__ == "__main__":
    try:
        create_database()
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
