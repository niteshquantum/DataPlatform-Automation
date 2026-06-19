import os
import sys
import logging
import configparser
import pandas as pd

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
# Paths
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

DATASET_DIR = os.path.join(
    PROJECT_ROOT,
    "datasets",
    "sqlserver"
)

# ============================================================
# Configuration
# ============================================================

def load_configuration():

    config = configparser.ConfigParser()

    if not os.path.exists(CONFIG_FILE):
        raise FileNotFoundError(
            f"Configuration file not found: {CONFIG_FILE}"
        )

    config.read(CONFIG_FILE)

    if "sqlserver" not in config:
        raise ValueError(
            "Missing [sqlserver] section"
        )

    return config


# ============================================================
# CSV Loader
# ============================================================

def load_csv(filename):

    file_path = os.path.join(
        DATASET_DIR,
        filename
    )

    if not os.path.exists(file_path):
        raise FileNotFoundError(
            f"Dataset not found: {file_path}"
        )

    LOGGER.info(
        "Loading dataset: %s",
        filename
    )

    return pd.read_csv(file_path)


# ============================================================
# Customers
# ============================================================

def load_customers(cursor, dataframe):

    LOGGER.info(
        "Loading Customers (%s rows)",
        len(dataframe)
    )

    cursor.execute(
        "DELETE FROM Orders"
    )

    cursor.execute(
        "DELETE FROM Customers"
    )

    records = [
        (
            int(row.CustomerID),
            str(row.CustomerName)
        )
        for row in dataframe.itertuples(index=False)
    ]

    cursor.fast_executemany = True

    cursor.executemany(
        """
        INSERT INTO Customers
        (
            CustomerID,
            CustomerName
        )
        VALUES (?, ?)
        """,
        records
    )


# ============================================================
# Products
# ============================================================

def load_products(cursor, dataframe):

    LOGGER.info(
        "Loading Products (%s rows)",
        len(dataframe)
    )

    cursor.execute(
        "DELETE FROM Products"
    )

    records = [
        (
            int(row.ProductID),
            str(row.ProductName)
        )
        for row in dataframe.itertuples(index=False)
    ]

    cursor.fast_executemany = True

    cursor.executemany(
        """
        INSERT INTO Products
        (
            ProductID,
            ProductName
        )
        VALUES (?, ?)
        """,
        records
    )


# ============================================================
# Orders
# ============================================================

def load_orders(cursor, dataframe):

    LOGGER.info(
        "Loading Orders (%s rows)",
        len(dataframe)
    )

    cursor.execute(
        "DELETE FROM Orders"
    )

    records = [
        (
            int(row.OrderID),
            int(row.CustomerID),
            int(row.ProductID)
        )
        for row in dataframe.itertuples(index=False)
    ]

    cursor.fast_executemany = True

    cursor.executemany(
        """
        INSERT INTO Orders
        (
            OrderID,
            CustomerID,
            ProductID
        )
        VALUES (?, ?, ?)
        """,
        records
    )


# ============================================================
# Validation
# ============================================================

def validate_row_count(
    cursor,
    table_name,
    expected_count
):

    cursor.execute(
        f"SELECT COUNT(*) FROM {table_name}"
    )

    actual_count = cursor.fetchone()[0]

    if actual_count != expected_count:

        raise RuntimeError(
            f"Row count validation failed "
            f"for {table_name}. "
            f"Expected={expected_count}, "
            f"Actual={actual_count}"
        )

    LOGGER.info(
        "%s validation successful (%s rows)",
        table_name,
        actual_count
    )


# ============================================================
# Load Data
# ============================================================

def load_data():

    connection = None

    try:

        load_configuration()

        customers_df = load_csv(
            "Customers.csv"
        )

        products_df = load_csv(
            "Products.csv"
        )

        orders_df = load_csv(
            "Orders.csv"
        )

        connection = get_connection()

        cursor = connection.cursor()

        load_customers(
            cursor,
            customers_df
        )

        load_products(
            cursor,
            products_df
        )

        load_orders(
            cursor,
            orders_df
        )

        connection.commit()

        LOGGER.info(
            "Transaction committed successfully"
        )

        validate_row_count(
            cursor,
            "Customers",
            len(customers_df)
        )

        validate_row_count(
            cursor,
            "Products",
            len(products_df)
        )

        validate_row_count(
            cursor,
            "Orders",
            len(orders_df)
        )

        LOGGER.info(
            "Data load completed successfully"
        )

        return True

    except Exception as exc:

        LOGGER.error(
            "Data load failed: %s",
            exc
        )

        if connection:
            connection.rollback()
            LOGGER.info(
                "Transaction rolled back"
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

        if load_data():

            sys.exit(0)

        sys.exit(1)

    except Exception as exc:

        LOGGER.error(
            "Unexpected error: %s",
            exc
        )

        sys.exit(1)


if __name__ == "__main__":
    main()