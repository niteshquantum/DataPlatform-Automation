import sys
import logging

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
# Validation Helpers
# ============================================================

def execute_scalar(cursor, query):
    """
    Execute scalar query and return value.
    """

    cursor.execute(query)

    result = cursor.fetchone()

    if result is None:
        return None

    return result[0]


def validate_row_counts(cursor):
    """
    Validate table row counts.
    """

    LOGGER.info(
        "Validating table row counts"
    )

    customers_count = execute_scalar(
        cursor,
        "SELECT COUNT(*) FROM Customers"
    )

    products_count = execute_scalar(
        cursor,
        "SELECT COUNT(*) FROM Products"
    )

    orders_count = execute_scalar(
        cursor,
        "SELECT COUNT(*) FROM Orders"
    )

    LOGGER.info(
        "Customers Row Count: %s",
        customers_count
    )

    LOGGER.info(
        "Products Row Count: %s",
        products_count
    )

    LOGGER.info(
        "Orders Row Count: %s",
        orders_count
    )

    if customers_count <= 0:
        raise RuntimeError(
            "Customers table is empty"
        )

    if products_count <= 0:
        raise RuntimeError(
            "Products table is empty"
        )

    if orders_count <= 0:
        raise RuntimeError(
            "Orders table is empty"
        )

    return {
        "customers": customers_count,
        "products": products_count,
        "orders": orders_count
    }


def validate_null_checks(cursor):
    """
    Validate NULL values in Orders.
    """

    LOGGER.info(
        "Validating NULL constraints"
    )

    null_customer_count = execute_scalar(
        cursor,
        """
        SELECT COUNT(*)
        FROM Orders
        WHERE CustomerID IS NULL
        """
    )

    null_product_count = execute_scalar(
        cursor,
        """
        SELECT COUNT(*)
        FROM Orders
        WHERE ProductID IS NULL
        """
    )

    if null_customer_count > 0:
        raise RuntimeError(
            f"Found {null_customer_count} NULL CustomerID values"
        )

    if null_product_count > 0:
        raise RuntimeError(
            f"Found {null_product_count} NULL ProductID values"
        )

    LOGGER.info(
        "NULL validation successful"
    )


def validate_customer_relationship(cursor):
    """
    Validate Orders -> Customers relationship.
    """

    LOGGER.info(
        "Validating Orders -> Customers relationship"
    )

    orphan_count = execute_scalar(
        cursor,
        """
        SELECT COUNT(*)
        FROM Orders o
        LEFT JOIN Customers c
            ON o.CustomerID = c.CustomerID
        WHERE c.CustomerID IS NULL
        """
    )

    if orphan_count > 0:
        raise RuntimeError(
            f"Found {orphan_count} orphan customer references"
        )

    LOGGER.info(
        "Orders -> Customers validation successful"
    )


def validate_product_relationship(cursor):
    """
    Validate Orders -> Products relationship.
    """

    LOGGER.info(
        "Validating Orders -> Products relationship"
    )

    orphan_count = execute_scalar(
        cursor,
        """
        SELECT COUNT(*)
        FROM Orders o
        LEFT JOIN Products p
            ON o.ProductID = p.ProductID
        WHERE p.ProductID IS NULL
        """
    )

    if orphan_count > 0:
        raise RuntimeError(
            f"Found {orphan_count} orphan product references"
        )

    LOGGER.info(
        "Orders -> Products validation successful"
    )


def generate_summary(row_counts):
    """
    Generate validation summary.
    """

    LOGGER.info(
        "=================================================="
    )

    LOGGER.info(
        "VALIDATION SUMMARY"
    )

    LOGGER.info(
        "=================================================="
    )

    LOGGER.info(
        "Customers Rows : %s",
        row_counts["customers"]
    )

    LOGGER.info(
        "Products Rows  : %s",
        row_counts["products"]
    )

    LOGGER.info(
        "Orders Rows    : %s",
        row_counts["orders"]
    )

    LOGGER.info(
        "Referential Integrity : PASSED"
    )

    LOGGER.info(
        "NULL Validation       : PASSED"
    )

    LOGGER.info(
        "=================================================="
    )


# ============================================================
# Main Validation
# ============================================================

def validate_data():

    connection = None

    try:

        LOGGER.info(
            "Starting data validation"
        )

        connection = get_connection()

        cursor = connection.cursor()

        row_counts = validate_row_counts(
            cursor
        )

        validate_null_checks(
            cursor
        )

        validate_customer_relationship(
            cursor
        )

        validate_product_relationship(
            cursor
        )

        generate_summary(
            row_counts
        )

        LOGGER.info(
            "Data validation completed successfully"
        )

        return True

    except Exception as exc:

        LOGGER.error(
            "Data validation failed: %s",
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

        if validate_data():

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