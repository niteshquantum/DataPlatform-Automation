import sys
from db_connection import get_connection


EXPECTED_COUNTS = {
    "customers":    100,
    "sellers":       50,
    "products":     100,
    "orders":       500,
    "orderdetails": 500
}


def validate_data():

    print("=" * 60)
    print("DATA VALIDATION")
    print("=" * 60)

    connection = get_connection()
    cursor     = connection.cursor()

    all_passed = True

    for table, expected in EXPECTED_COUNTS.items():

        cursor.execute(f"SELECT COUNT(*) FROM {table}")

        actual = cursor.fetchone()[0]

        status = "PASS" if actual >= expected else "WARN"

        if actual == 0:
            status = "FAIL"
            all_passed = False

        print(
            f"{table:<20} Expected: {expected:<6} "
            f"Actual: {actual:<6} [{status}]"
        )

    cursor.close()
    connection.close()

    if all_passed:
        print("\nData validation completed successfully")
    else:
        print("\nData validation completed with warnings")

    return all_passed


if __name__ == "__main__":
    try:
        ok = validate_data()
        sys.exit(0 if ok else 1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
