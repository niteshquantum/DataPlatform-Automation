import os
import sys
import pandas as pd


EXPECTED_SCHEMAS = {

    "Customers": [
        "customer_id",
        "customer_name",
        "email",
        "city"
    ],

    "Sellers": [
        "seller_id",
        "seller_name"
    ],

    "Products": [
        "product_id",
        "product_name",
        "category",
        "price"
    ],

    "Orders": [
        "order_id",
        "customer_id",
        "product_id",
        "quantity",
        "order_date"
    ],

    "OrderDetails": [
        "orderdetail_id",
        "order_id",
        "product_id",
        "quantity",
        "unit_price"
    ]
}


def get_project_root():
    return os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", "..")
    )


def validate_all_schemas():

    print("=" * 60)
    print("CSV SCHEMA VALIDATION")
    print("=" * 60)

    dataset_dir = os.path.join(
        get_project_root(),
        "datasets",
        "postgresql"
    )

    all_passed = True

    for dataset_name, expected_cols in EXPECTED_SCHEMAS.items():

        file_path = os.path.join(dataset_dir, f"{dataset_name}.csv")

        if not os.path.exists(file_path):
            print(f"MISSING  : {dataset_name}.csv")
            all_passed = False
            continue

        df = pd.read_csv(file_path)

        actual_cols = list(df.columns)

        if actual_cols == expected_cols:
            print(f"PASS     : {dataset_name}.csv ({len(df)} rows)")
        else:
            print(f"FAIL     : {dataset_name}.csv")
            print(f"  Expected : {expected_cols}")
            print(f"  Actual   : {actual_cols}")
            all_passed = False

    if all_passed:
        print("\nAll schemas valid")
    else:
        print("\nSchema validation failed")

    return all_passed


if __name__ == "__main__":
    try:
        ok = validate_all_schemas()
        sys.exit(0 if ok else 1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
