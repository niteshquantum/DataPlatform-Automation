import sys
from db_connection import get_connection


TABLES = [
    "orderdetails",
    "orders",
    "products",
    "sellers",
    "customers"
]


def truncate_tables():

    connection = get_connection()
    cursor     = connection.cursor()

    try:

        print("=" * 60)
        print("TRUNCATING TABLES")
        print("=" * 60)

        for table in TABLES:

            cursor.execute(
                f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE;"
            )

            print(f"Truncated : {table}")

        connection.commit()

        print("\nAll tables truncated successfully")

    except Exception as e:

        connection.rollback()

        raise Exception(f"Table truncation failed : {e}")

    finally:

        cursor.close()
        connection.close()


if __name__ == "__main__":
    try:
        truncate_tables()
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
