from pathlib import Path
import pandas as pd

from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

csv_file = ROOT / "datasets" / "mssql" / "products.csv"

df = pd.read_csv(csv_file)

conn = get_connection()
cursor = conn.cursor()

insert_sql = """
INSERT INTO Products
(
    ProductID,
    ProductName,
    Category,
    Price,
    Stock,
    SellerID
)
VALUES
(
    ?, ?, ?, ?, ?, ?
)
"""

for _, row in df.iterrows():

    cursor.execute(
        insert_sql,
        (
            row["ProductID"],
            row["ProductName"],
            row["Category"],
            row["Price"],
            row["Stock"],
            row["SellerID"]
        )
    )

conn.commit()

print(f"{len(df)} rows loaded into Products")

cursor.close()
conn.close()