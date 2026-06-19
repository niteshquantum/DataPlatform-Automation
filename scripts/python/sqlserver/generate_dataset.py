import os
import sys
import logging
import configparser
import pandas as pd
from pathlib import Path

# ============================================================
# Logging Configuration
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

LOGGER = logging.getLogger(__name__)

# ============================================================
# Project Paths
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[3]

CONFIG_FILE = PROJECT_ROOT / "config" / "sqlserver.conf"

DATASET_DIR = PROJECT_ROOT / "datasets" / "sqlserver"

# ============================================================
# Configuration
# ============================================================

def load_configuration():
    """
    Load SQL Server configuration.
    """

    if not CONFIG_FILE.exists():
        raise FileNotFoundError(
            f"Configuration file not found: {CONFIG_FILE}"
        )

    config = configparser.ConfigParser()

    config.read(CONFIG_FILE)

    if "sqlserver" not in config:
        raise ValueError(
            "Missing [sqlserver] section in configuration"
        )

    return config


# ============================================================
# Dataset Directory
# ============================================================

def create_dataset_directory():
    """
    Create dataset directory if it does not exist.
    """

    DATASET_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    LOGGER.info(
        "Dataset directory ready: %s",
        DATASET_DIR
    )


# ============================================================
# Customers Dataset
# ============================================================

def generate_customers():
    """
    Generate Customers dataset.
    """

    customers = []

    for customer_id in range(1, 101):

        customers.append({
            "CustomerID": customer_id,
            "CustomerName": f"Customer_{customer_id:03d}"
        })

    dataframe = pd.DataFrame(customers)

    output_file = DATASET_DIR / "Customers.csv"

    dataframe.to_csv(
        output_file,
        index=False
    )

    LOGGER.info(
        "Generated Customers.csv (%s rows)",
        len(dataframe)
    )

    return output_file


# ============================================================
# Products Dataset
# ============================================================

def generate_products():
    """
    Generate Products dataset.
    """

    products = []

    categories = [
        "Laptop",
        "Mobile",
        "Keyboard",
        "Mouse",
        "Monitor",
        "Printer",
        "Tablet",
        "Headphone",
        "Camera",
        "Speaker"
    ]

    for product_id in range(1, 101):

        category = categories[
            (product_id - 1) % len(categories)
        ]

        products.append({
            "ProductID": product_id,
            "ProductName": f"{category}_{product_id:03d}"
        })

    dataframe = pd.DataFrame(products)

    output_file = DATASET_DIR / "Products.csv"

    dataframe.to_csv(
        output_file,
        index=False
    )

    LOGGER.info(
        "Generated Products.csv (%s rows)",
        len(dataframe)
    )

    return output_file


# ============================================================
# Orders Dataset
# ============================================================

def generate_orders():
    """
    Generate Orders dataset.
    """

    orders = []

    for order_id in range(1, 501):

        customer_id = ((order_id - 1) % 100) + 1
        product_id = ((order_id * 7) % 100) + 1

        orders.append({
            "OrderID": order_id,
            "CustomerID": customer_id,
            "ProductID": product_id
        })

    dataframe = pd.DataFrame(orders)

    output_file = DATASET_DIR / "Orders.csv"

    dataframe.to_csv(
        output_file,
        index=False
    )

    LOGGER.info(
        "Generated Orders.csv (%s rows)",
        len(dataframe)
    )

    return output_file


# ============================================================
# Validation
# ============================================================

def validate_file(file_path, expected_rows):
    """
    Validate generated dataset file.
    """

    if not file_path.exists():

        raise FileNotFoundError(
            f"Dataset file not found: {file_path}"
        )

    dataframe = pd.read_csv(file_path)

    actual_rows = len(dataframe)

    if actual_rows != expected_rows:

        raise ValueError(
            f"Row count mismatch for "
            f"{file_path.name}. "
            f"Expected={expected_rows}, "
            f"Actual={actual_rows}"
        )

    LOGGER.info(
        "Validated %s (%s rows)",
        file_path.name,
        actual_rows
    )


# ============================================================
# Dataset Generation
# ============================================================

def generate_datasets():
    """
    Generate all datasets.
    """

    create_dataset_directory()

    customers_file = generate_customers()

    products_file = generate_products()

    orders_file = generate_orders()

    validate_file(
        customers_file,
        100
    )

    validate_file(
        products_file,
        100
    )

    validate_file(
        orders_file,
        500
    )

    LOGGER.info(
        "All datasets generated successfully"
    )


# ============================================================
# Main
# ============================================================

def main():

    try:

        LOGGER.info(
            "Starting dataset generation"
        )

        load_configuration()

        generate_datasets()

        LOGGER.info(
            "Dataset generation completed successfully"
        )

        sys.exit(0)

    except Exception as exc:

        LOGGER.exception(
            "Dataset generation failed: %s",
            exc
        )

        sys.exit(1)


if __name__ == "__main__":
    main()