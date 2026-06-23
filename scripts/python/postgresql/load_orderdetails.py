import pandas as pd
from db_connection import get_connection


def load_orderdetails(csv_file):

    dataframe = pd.read_csv(csv_file)

    connection = get_connection()
    cursor     = connection.cursor()
    inserted   = 0

    for _, row in dataframe.iterrows():

        cursor.execute(
            """
            INSERT INTO orderdetails
            (orderdetail_id, order_id, product_id, quantity, unit_price)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                int(row["orderdetail_id"]),
                int(row["order_id"]),
                int(row["product_id"]),
                int(row["quantity"]),
                float(row["unit_price"])
            )
        )

        inserted += 1

    connection.commit()
    cursor.close()
    connection.close()

    print(f"OrderDetails Loaded : {inserted}")


if __name__ == "__main__":
    print("Use from load_all.py")