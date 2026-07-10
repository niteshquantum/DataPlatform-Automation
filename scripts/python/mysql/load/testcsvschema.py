from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[4]
incoming_dir = ROOT / "incoming" / "mysql"

for csv_file in sorted(incoming_dir.glob("*.csv")):
    last_error = None
    for encoding in ["utf-8-sig", "cp1252", "latin-1"]:
        try:
            df = pd.read_csv(csv_file, nrows=0, encoding=encoding)
            columns = [
                column.replace("\ufeff", "").strip()
                for column in df.columns
            ]
            print(f"{csv_file.name}: {columns}")
            break
        except UnicodeDecodeError as exc:
            last_error = exc
    else:
        raise last_error
