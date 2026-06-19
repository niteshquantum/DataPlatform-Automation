import sys
import logging
import configparser
from pathlib import Path

from db_connection import get_connection

# ============================================================
# Logging
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

LOGGER = logging.getLogger(__name__)

# ============================================================
# Configuration
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[3]

CONFIG_FILE = PROJECT_ROOT / "config" / "sqlserver.conf"

VALIDATION_PASSED = True


def load_configuration():

    if not CONFIG_FILE.exists():
        raise FileNotFoundError(
            f"Configuration file not found: {CONFIG_FILE}"
        )

    config = configparser.ConfigParser()

    config.read(CONFIG_FILE)

    if "sqlserver" not in config:
        raise ValueError(
            "Missing [sqlserver] section"
        )

    return config


def report(label, status):

    global VALIDATION_PASSED

    if status:
        LOGGER.info("[PASS] %s", label)
    else:
        LOGGER.error("[FAIL] %s", label)
        VALIDATION_PASSED = False


def execute_scalar(cursor, query):

    cursor.execute(query)

    row = cursor.fetchone()

    if row is None:
        return None

    return row[0]


def validate_connectivity():

    connection = None

    try:

        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute("SELECT 1")

        report(
            "SQL Server Connectivity",
            True
        )

        return True

    except Exception:

        report(
            "SQL Server Connectivity",
            False
        )

        return False

    finally:

        if connection:
            connection.close()


def validate_database(cursor, database_name):

    count = execute_scalar(
        cursor,
        f"""
        SELECT COUNT(*)
        FROM sys.databases
        WHERE name='{database_name}'
        """
    )

    report(
        f"Database Exists ({database_name})",
        count == 1
    )


def validate_table(cursor, table_name):

    count = execute_scalar(
        cursor,
        f"""
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_NAME='{table_name}'
        """
    )

    report(
        f"Table Exists ({table_name})",
        count == 1
    )


def validate_data(cursor, table_name):

    count = execute_scalar(
        cursor,
        f"SELECT COUNT(*) FROM {table_name}"
    )

    report(
        f"Data Exists ({table_name})",
        count > 0
    )


def main():

    connection = None

    try:

        LOGGER.info(
            "=================================================="
        )

        LOGGER.info(
            "SQL SERVER VALIDATION REPORT"
        )

        LOGGER.info(
            "=================================================="
        )

        config = load_configuration()

        database_name = (
            config["sqlserver"]["DATABASE_NAME"]
        )

        if not validate_connectivity():
            sys.exit(1)

        connection = get_connection()

        cursor = connection.cursor()

        validate_database(
            cursor,
            database_name
        )

        validate_table(
            cursor,
            "Customers"
        )

        validate_table(
            cursor,
            "Products"
        )

        validate_table(
            cursor,
            "Orders"
        )

        validate_data(
            cursor,
            "Customers"
        )

        validate_data(
            cursor,
            "Products"
        )

        validate_data(
            cursor,
            "Orders"
        )

        LOGGER.info(
            "=================================================="
        )

        if VALIDATION_PASSED:

            LOGGER.info(
                "ALL VALIDATIONS PASSED"
            )

            LOGGER.info(
                "=================================================="
            )

            sys.exit(0)

        LOGGER.error(
            "VALIDATION FAILED"
        )

        LOGGER.error(
            "=================================================="
        )

        sys.exit(1)

    except Exception as exc:

        LOGGER.exception(
            "Validation failed: %s",
            exc
        )

        sys.exit(1)

    finally:

        if connection:
            connection.close()


if __name__ == "__main__":
    main()