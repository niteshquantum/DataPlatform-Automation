import sys
from db_connection import get_connection


TABLES = [
    "customers",
    "sellers",
    "products",
    "orders",
    "orderdetails"
]


def validate_loaded_data():

    connection = get_connection()
    cursor     = connection.cursor()

    print("=" * 60)
    print("LOADED DATA VALIDATION")
    print("=" * 60)

    all_passed = True

    for table in TABLES:

        cursor.execute(f"SELECT COUNT(*) FROM {table}")

        count = cursor.fetchone()[0]

        status = "OK" if count > 0 else "EMPTY"

        if count == 0:
            all_passed = False

        print(f"{table:<20} {count:<8} [{status}]")

    cursor.close()
    connection.close()

    if all_passed:
        print("\nAll tables have data")
    else:
        print("\nWARNING: Some tables are empty")

    return all_passed


if __name__ == "__main__":
    try:
        validate_loaded_data()
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
