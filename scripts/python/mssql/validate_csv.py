from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[3]

DATASET_DIR = ROOT / "datasets" / "mssql"

required_files = [
    "Customers.csv",
    "Sellers.csv",
    "Products.csv",
    "Orders.csv",
    "OrderDetails.csv"
]

try:

    print()
    print("=" * 50)
    print("CSV VALIDATION")
    print("=" * 50)

    for file_name in required_files:

        file_path = DATASET_DIR / file_name

        if not file_path.exists():
            raise Exception(f"Missing file: {file_name}")

        df = pd.read_csv(file_path)

        print(f"{file_name:<20} {len(df)} rows")

    print("=" * 50)
    print("CSV VALIDATION SUCCESS")
    print("=" * 50)

except Exception as e:

    print("=" * 50)
    print("CSV VALIDATION FAILED")
    print("=" * 50)
    print(e)
    print("=" * 50)

    exit(1)