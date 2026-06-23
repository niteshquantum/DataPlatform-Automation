from db_connection import get_connection


def validate_postgresql():

    connection = None

    try:

        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute("SELECT version();")

        version = cursor.fetchone()[0]

        print("=" * 60)
        print("POSTGRESQL VALIDATION")
        print("=" * 60)

        print(f"Version : {version}")

        cursor.close()

        return True

    except Exception as error:

        print(f"Validation Failed : {error}")

        return False

    finally:

        if connection:
            connection.close()


if __name__ == "__main__":
    validate_postgresql()