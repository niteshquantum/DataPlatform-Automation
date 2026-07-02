from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config
from scripts.python.mssql.setup.db_connection import get_connection


def create_database():

    config = load_database_config("mssql")

    database_name = config["MSSQL_DB"]

    print("=" * 60)
    print("CREATE MSSQL DATABASE")
    print("=" * 60)
    print(f"Database : {database_name}")
    print(f"Host     : {config['MSSQL_HOST']}")
    print(f"Port     : {config['MSSQL_PORT']}")
    print()

    connection = None
    cursor = None

    try:

        connection = get_connection("master")

        connection.autocommit = True

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT COUNT(*)
            FROM sys.databases
            WHERE name = ?
            """,
            database_name
        )

        exists = cursor.fetchone()[0]

        if exists:

            print(f"Database already exists : {database_name}")

        else:

            cursor.execute(
                f"CREATE DATABASE [{database_name}]"
            )

            print(f"Database created : {database_name}")

        cursor.execute(
            """
            SELECT COUNT(*)
            FROM sys.databases
            WHERE name = ?
            """,
            database_name
        )

        validation = cursor.fetchone()[0]

        if validation != 1:
            raise RuntimeError(
                f"Database validation failed : {database_name}"
            )

        print()
        print("Database validation successful.")

    finally:

        if cursor:
            cursor.close()

        if connection:
            connection.close()


if __name__ == "__main__":

    try:

        create_database()

    except Exception as error:

        print(f"\nERROR : {error}")

        sys.exit(1)