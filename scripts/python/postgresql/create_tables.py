import sys
from db_connection import get_connection


TABLES_SQL = [

    (
        "customers",
        """
        CREATE TABLE IF NOT EXISTS customers (
            customer_id   SERIAL        PRIMARY KEY,
            customer_name VARCHAR(255)  NOT NULL,
            email         VARCHAR(255),
            city          VARCHAR(100)
        )
        """
    ),

    (
        "sellers",
        """
        CREATE TABLE IF NOT EXISTS sellers (
            seller_id   SERIAL       PRIMARY KEY,
            seller_name VARCHAR(255) NOT NULL
        )
        """
    ),

    (
        "products",
        """
        CREATE TABLE IF NOT EXISTS products (
            product_id   SERIAL         PRIMARY KEY,
            product_name VARCHAR(255)   NOT NULL,
            category     VARCHAR(100),
            price        NUMERIC(12, 2)
        )
        """
    ),

    (
        "orders",
        """
        CREATE TABLE IF NOT EXISTS orders (
            order_id    SERIAL  PRIMARY KEY,
            customer_id INTEGER REFERENCES customers(customer_id),
            product_id  INTEGER REFERENCES products(product_id),
            quantity    INTEGER,
            order_date  DATE
        )
        """
    ),

    (
        "orderdetails",
        """
        CREATE TABLE IF NOT EXISTS orderdetails (
            orderdetail_id SERIAL         PRIMARY KEY,
            order_id       INTEGER        REFERENCES orders(order_id),
            product_id     INTEGER        REFERENCES products(product_id),
            quantity       INTEGER,
            unit_price     NUMERIC(12, 2)
        )
        """
    )
]


def create_tables():

    print("=" * 60)
    print("CREATE TABLES")
    print("=" * 60)

    connection = get_connection()
    cursor     = connection.cursor()

    try:

        for table_name, sql in TABLES_SQL:

            cursor.execute(sql)

            print(f"Table ready : {table_name}")

        connection.commit()

        print("\nAll tables created successfully")

    except Exception as e:

        connection.rollback()

        raise Exception(f"Create tables failed : {e}")

    finally:

        cursor.close()
        connection.close()


if __name__ == "__main__":
    try:
        create_tables()
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
