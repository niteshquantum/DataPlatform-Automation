from db_connection import get_connection


def test_connection():

    connection = None

    try:

        connection = get_connection()

        print(
            "SUCCESS : PostgreSQL connection established"
        )

        return True

    except Exception as error:

        print(
            f"FAILED : {error}"
        )

        return False

    finally:

        if connection:
            connection.close()


if __name__ == "__main__":
    test_connection()