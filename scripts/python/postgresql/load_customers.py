import pandas as pd
from db_connection import get_connection


def load_customers(csv_file):

    dataframe = pd.read_csv(csv_file)

    connection = get_connection()
    cursor     = connection.cursor()
    inserted   = 0

    for _, row in dataframe.iterrows():

        cursor.execute(
            """
            INSERT INTO customers
            (customer_id, customer_name, email, city)
            VALUES (%s, %s, %s, %s)
            """,
            (
                int(row["customer_id"]),
                str(row["customer_name"]),
                str(row["email"]),
                str(row["city"])
            )
        )

        inserted += 1

    connection.commit()
    cursor.close()
    connection.close()

    print(f"Customers Loaded : {inserted}")


if __name__ == "__main__":
    print("Use from load_all.py")