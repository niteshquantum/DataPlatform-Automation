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
# Table Definitions
# ============================================================

CUSTOMERS_TABLE_SQL = """
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'Customers'
)
BEGIN
    CREATE TABLE Customers (
        CustomerID INT NOT NULL,
        CustomerName VARCHAR(255) NOT NULL,

        CONSTRAINT PK_Customers
            PRIMARY KEY (CustomerID)
    )
END
"""

PRODUCTS_TABLE_SQL = """
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'Products'
)
BEGIN
    CREATE TABLE Products (
        ProductID INT NOT NULL,
        ProductName VARCHAR(255) NOT NULL,

        CONSTRAINT PK_Products
            PRIMARY KEY (ProductID)
    )
END
"""

ORDERS_TABLE_SQL = """
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'Orders'
)
BEGIN
    CREATE TABLE Orders (
        OrderID INT NOT NULL,
        CustomerID INT NOT NULL,
        ProductID INT NOT NULL,

        CONSTRAINT PK_Orders
            PRIMARY KEY (OrderID),

        CONSTRAINT FK_Orders_Customers
            FOREIGN KEY (CustomerID)
            REFERENCES Customers(CustomerID),

        CONSTRAINT FK_Orders_Products
            FOREIGN KEY (ProductID)
            REFERENCES Products(ProductID)
    )
END
"""


# ============================================================
# Validation Functions
# ============================================================

def validate_table(cursor, table_name):
    """
    Validate table existence.
    """

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_NAME = ?
        """,
        table_name
    )

    result = cursor.fetchone()[0]

    return result == 1


# ============================================================
# Table Creation
# ============================================================

def create_tables():
    """
    Create required SQL Server tables.
    """

    config = load_configuration()

    database_name = config["sqlserver"]["DATABASE_NAME"]

    connection = None

    try:

        LOGGER.info(
            "Connecting to database: %s",
            database_name
        )

        connection = get_connection(database_name)

        cursor = connection.cursor()

        LOGGER.info(
            "Creating Customers table"
        )

        cursor.execute(
            CUSTOMERS_TABLE_SQL
        )

        LOGGER.info(
            "Creating Products table"
        )

        cursor.execute(
            PRODUCTS_TABLE_SQL
        )

        LOGGER.info(
            "Creating Orders table"
        )

        cursor.execute(
            ORDERS_TABLE_SQL
        )

        connection.commit()

        LOGGER.info(
            "Table creation completed"
        )

        required_tables = [
            "Customers",
            "Products",
            "Orders"
        ]

        for table_name in required_tables:

            if not validate_table(
                cursor,
                table_name
            ):
                raise RuntimeError(
                    f"Table validation failed: {table_name}"
                )

            LOGGER.info(
                "Validated table: %s",
                table_name
            )

        LOGGER.info(
            "All tables validated successfully"
        )

        return True

    except Exception as exc:

        LOGGER.error(
            "Table creation failed: %s",
            exc
        )

        if connection:
            connection.rollback()

        return False

    finally:

        if connection:
            connection.close()


# ============================================================
# Main
# ============================================================

def main():

    try:

        if create_tables():

            LOGGER.info(
                "Table creation completed successfully"
            )

            sys.exit(0)

        LOGGER.error(
            "Table creation failed"
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