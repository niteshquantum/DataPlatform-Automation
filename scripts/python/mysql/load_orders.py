from pathlib import Path
import pandas as pd

from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

csv_file = ROOT / "datasets" / "mysql" / "Orders.csv"

df = pd.read_csv(csv_file)

conn = get_connection()
cursor = conn.cursor()

insert_sql = """
INSERT INTO Orderstable
(
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount,
    Status
)
VALUES
(
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
            row["OrderID"],
            row["CustomerID"],
            row["OrderDate"],
            row["TotalAmount"],
            row["Status"]
        )
    )

conn.commit()

print("Orders Load Successful")

cursor.close()
conn.close()