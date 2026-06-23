import pandas as pd
from db_connection import get_connection


def load_sellers(csv_file):

    dataframe = pd.read_csv(csv_file)

    connection = get_connection()
    cursor     = connection.cursor()
    inserted   = 0

    for _, row in dataframe.iterrows():

        cursor.execute(
            """
            INSERT INTO sellers
            (seller_id, seller_name)
            VALUES (%s, %s)
            """,
            (
                int(row["seller_id"]),
                str(row["seller_name"])
            )
        )

        inserted += 1

    connection.commit()
    cursor.close()
    connection.close()

    print(f"Sellers Loaded : {inserted}")


if __name__ == "__main__":
    print("Use from load_all.py")