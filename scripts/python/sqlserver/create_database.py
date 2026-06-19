import sys
import logging
import configparser
from db_connection import get_connection

# ============================================================
# Logging Configuration
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

LOGGER = logging.getLogger(__name__)

# ============================================================
# Configuration
# ============================================================

def load_configuration():
    """
    Load SQL Server configuration.
    """

    config = configparser.ConfigParser()
    config.read("config/sqlserver.conf")

    if "sqlserver" not in config:
        raise ValueError(
            "Missing [sqlserver] section in config/sqlserver.conf"
        )

    return config


# ============================================================
# Database Creation
# ============================================================

def create_database():

    config = load_configuration()

    database_name = config["sqlserver"]["DATABASE_NAME"]

    connection = None

    try:

        LOGGER.info(
            "Connecting to master database"
        )

        connection = get_connection("master")

        connection.autocommit = True

        cursor = connection.cursor()

        LOGGER.info(
            "Checking database existence: %s",
            database_name
        )

        cursor.execute(
            """
            SELECT COUNT(*)
            FROM sys.databases
            WHERE name = ?
            """,
            database_name
        )

        database_exists = cursor.fetchone()[0]

        if database_exists > 0:

            LOGGER.info(
                "Database already exists: %s",
                database_name
            )

            return True

        LOGGER.info(
            "Creating database: %s",
            database_name
        )

        cursor.execute(
            f"CREATE DATABASE [{database_name}]"
        )

        LOGGER.info(
            "Database created successfully"
        )

        cursor.execute(
            """
            SELECT COUNT(*)
            FROM sys.databases
            WHERE name = ?
            """,
            database_name
        )

        validation_result = cursor.fetchone()[0]

        if validation_result != 1:

            raise RuntimeError(
                f"Database validation failed: {database_name}"
            )

        LOGGER.info(
            "Database validation successful"
        )

        return True

    except Exception as exc:

        LOGGER.error(
            "Database creation failed: %s",
            exc
        )

        return False

    finally:

        if connection:
            connection.close()


# ============================================================
# Main
# ============================================================

def main():

    try:

        if create_database():

            LOGGER.info(
                "Database creation completed successfully"
            )

            sys.exit(0)

        LOGGER.error(
            "Database creation failed"
        )

        sys.exit(1)

    except Exception as exc:

        LOGGER.error(
            "Unexpected error: %s",
            exc
        )

        sys.exit(1)


if __name__ == "__main__":
    main()