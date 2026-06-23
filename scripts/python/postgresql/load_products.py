import pandas as pd
from db_connection import get_connection


def load_products(csv_file):

    dataframe = pd.read_csv(csv_file)

    connection = get_connection()
    cursor     = connection.cursor()
    inserted   = 0

    for _, row in dataframe.iterrows():

        cursor.execute(
            """
            INSERT INTO products
            (product_id, product_name, category, price)
            VALUES (%s, %s, %s, %s)
            """,
            (
                int(row["product_id"]),
                str(row["product_name"]),
                str(row["category"]),
                float(row["price"])
            )
        )

        inserted += 1

    connection.commit()
    cursor.close()
    connection.close()

    print(f"Products Loaded : {inserted}")


if __name__ == "__main__":
    print("Use from load_all.py")