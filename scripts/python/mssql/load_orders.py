from pathlib import Path
import pandas as pd

from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

csv_file = ROOT / "datasets" / "mssql" / "orders.csv"

df = pd.read_csv(csv_file)

conn = get_connection()
cursor = conn.cursor()

insert_sql = """
INSERT INTO OrdersTable
(
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount,
    Status
)
VALUES
(
    ?, ?, ?, ?, ?
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

print(f"{len(df)} rows loaded into OrdersTable")

cursor.close()
conn.close()