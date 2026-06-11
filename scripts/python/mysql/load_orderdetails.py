from pathlib import Path
import pandas as pd

from db_connection import get_connection

ROOT = Path(__file__).resolve().parents[3]

csv_file = ROOT / "datasets" / "mysql" / "OrderDetails.csv"

df = pd.read_csv(csv_file)

conn = get_connection()
cursor = conn.cursor()

insert_sql = """
INSERT INTO OrderDetails
(
    OrderDetailID,
    OrderID,
    ProductID,
    Quantity,
    UnitPrice
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
            row["OrderDetailID"],
            row["OrderID"],
            row["ProductID"],
            row["Quantity"],
            row["UnitPrice"]
        )
    )

rows_loaded = len(df)

conn.commit()

print(f"{rows_loaded} rows loaded into OrderDetails")


cursor.close()
conn.close()