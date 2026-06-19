from pathlib import Path
import pandas as pd

from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

df = pd.read_csv(
    ROOT / "datasets" / "mssql" / "customers.csv"
)

conn = get_connection()
cursor = conn.cursor()

sql = """
INSERT INTO Customers
(
CustomerID,
FirstName,
LastName,
City,
State,
JoinDate
)
VALUES (?, ?, ?, ?, ?, ?)
"""

for _, row in df.iterrows():

    cursor.execute(
        sql,
        (
            row["CustomerID"],
            row["FirstName"],
            row["LastName"],
            row["City"],
            row["State"],
            row["JoinDate"]
        )
    )

conn.commit()

print(f"{len(df)} rows loaded into Customers")

cursor.close()
conn.close()