from pathlib import Path
import pandas as pd

from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

csv_file = ROOT / "datasets" / "mssql" / "sellers.csv"

df = pd.read_csv(csv_file)

conn = get_connection()
cursor = conn.cursor()

insert_sql = """
INSERT INTO Sellers
(
    SellerID,
    SellerName,
    City,
    Rating
)
VALUES
(
    ?, ?, ?, ?
)
"""

for _, row in df.iterrows():

    cursor.execute(
        insert_sql,
        (
            row["SellerID"],
            row["SellerName"],
            row["City"],
            row["Rating"]
        )
    )

conn.commit()

print(f"{len(df)} rows loaded into Sellers")

cursor.close()
conn.close()