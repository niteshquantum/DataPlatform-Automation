from pathlib import Path
import subprocess
import sys



ROOT = Path(__file__).resolve().parents[3]

scripts = [
    "truncate_tables.py",
    "load_customers.py",
    "load_sellers.py",
    "load_products.py",
    "load_orders.py",
    "load_orderdetails.py"
]

for script in scripts:

    script_path = Path(__file__).parent / script

    print()
    print("=" * 50)
    print(f"RUNNING : {script}")
    print("=" * 50)

    result = subprocess.run(
        [sys.executable, str(script_path)],
        cwd=ROOT
    )

    if result.returncode != 0:
        print()
        print(f"FAILED : {script}")
        sys.exit(1)

print()
print("=" * 50)
print("ALL DATA LOADED SUCCESSFULLY")
print("=" * 50)