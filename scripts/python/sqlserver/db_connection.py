import os
import sys
import logging
import configparser
import pyodbc

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

PROJECT_ROOT = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        "..",
        "..",
        ".."
    )
)

CONFIG_FILE = os.path.join(
    PROJECT_ROOT,
    "config",
    "sqlserver.conf"
)

# ============================================================
# Config Loader
# ============================================================

def load_config():
    """
    Load SQL Server configuration.
    """

    if not os.path.exists(CONFIG_FILE):
        raise FileNotFoundError(
            f"Configuration file not found: {CONFIG_FILE}"
        )

    parser = configparser.ConfigParser()
    parser.read(CONFIG_FILE)

    if "sqlserver" not in parser:
        raise ValueError(
            "Missing [sqlserver] section in configuration"
        )

    return parser


# ============================================================
# Connection String
# ============================================================

def get_connection_string(database=None):
    """
    Build SQL Server connection string.
    """

    config = load_config()

    server = config["sqlserver"].get("SERVER", "localhost")
    port = config["sqlserver"].get("PORT", "1433")
    username = config["sqlserver"].get("SA_USERNAME", "SA")
    password = config["sqlserver"].get("SA_PASSWORD")

    if database is None:
        database = config["sqlserver"]["DATABASE_NAME"]

    connection_string = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={server},{port};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "TrustServerCertificate=yes;"
    )

    return connection_string


# ============================================================
# Database Connection
# ============================================================

def get_connection(database=None):
    """
    Create SQL Server connection.
    """

    try:

        connection_string = get_connection_string(database)

        connection = pyodbc.connect(
            connection_string,
            timeout=30
        )

        return connection

    except Exception as exc:
        LOGGER.error(
            "Failed to create SQL Server connection: %s",
            exc
        )
        raise


# ============================================================
# Connection Validation
# ============================================================

def validate_connection():
    """
    Validate SQL Server connectivity.
    """

    connection = None

    try:

        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute("SELECT 1")

        result = cursor.fetchone()

        if result is None:
            raise RuntimeError(
                "Connection validation query returned no result"
            )

        LOGGER.info(
            "SQL Server connection validation successful"
        )

        return True

    except Exception as exc:

        LOGGER.error(
            "Connection validation failed: %s",
            exc
        )

        return False

    finally:

        if connection:
            connection.close()


# ============================================================
# Script Entry Point
# ============================================================

def main():

    try:

        LOGGER.info(
            "Validating SQL Server connection"
        )

        if validate_connection():

            LOGGER.info(
                "Database connection successful"
            )

            sys.exit(0)

        LOGGER.error(
            "Database connection failed"
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