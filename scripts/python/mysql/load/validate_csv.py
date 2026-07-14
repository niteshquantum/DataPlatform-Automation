from pathlib import Path

import pandas as pd
import yaml

ROOT = Path(__file__).resolve().parents[4]

datasets_file = ROOT / "config" / "mysql" / "datasets.yaml"
datasets_dir = ROOT / "datasets" / "mysql"

try:
    with open(datasets_file, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    datasets = config["datasets"]

    print()
    print("=" * 50)
    print("CSV VALIDATION")
    print("=" * 50)

    for table_name, dataset_info in datasets.items():

        csv_file = datasets_dir / dataset_info["file"]

        if dataset_info.get("required", False):

            if not csv_file.exists():
                raise Exception(
                    f"Required file missing: {dataset_info['file']}"
                )

        df = pd.read_csv(csv_file)

        if df.empty:
            raise Exception(
                f"CSV file is empty: {dataset_info['file']}"
            )

        required_columns = dataset_info.get(
            "required_columns",
            []
        )

        missing_columns = [
            column
            for column in required_columns
            if column not in df.columns
        ]

        if missing_columns:
            raise Exception(
                f"{dataset_info['file']} missing columns: "
                f"{', '.join(missing_columns)}"
            )

        print(
            f"[OK] {dataset_info['file']} "
            f"({len(df)} rows)"
        )

    print("=" * 50)
    print("CSV VALIDATION SUCCESS")
    print("=" * 50)

except Exception as e:

    print()
    print("=" * 50)
    print("CSV VALIDATION FAILED")
    print("=" * 50)
    print(e)
    print("=" * 50)

    raise SystemExit(1)