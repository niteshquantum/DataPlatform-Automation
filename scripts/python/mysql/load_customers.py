from pathlib import Path
import pandas as pd
import mysql.connector

from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

csv_file = ROOT / "datasets" / "mysql" / "Customers.csv"

print(f"Loading: {csv_file}")

df = pd.read_csv(csv_file)

conn = get_connection()
cursor = conn.cursor()

insert_sql = """
INSERT INTO Customers
(
    CustomerID,
    FirstName,
    LastName,
    City,
    State,
    JoinDate
)
VALUES
(
    %s,
    %s,
    %s,
    %s,
    %s,
    %s
)
"""

for _, row in df.iterrows():

    cursor.execute(
        insert_sql,
        (
            row["CustomerID"],
            row["FirstName"],
            row["LastName"],
            row["City"],
            row["State"],
            row["JoinDate"]
        )
    )

rows_loaded = len(df)

conn.commit()

print(f"{rows_loaded} rows loaded into Customers")

cursor.close()
conn.close()

print("Customers Load Successful")