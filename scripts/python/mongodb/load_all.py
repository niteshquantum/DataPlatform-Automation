import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent

scripts = [
"create_collections.py",
"create_indexes.py",
"generate_dataset.py",
"load_data.py",
"validate_data.py"
]

for script in scripts:


    script_path = BASE_DIR / script

    print(f"Running {script}")

    subprocess.run(
        [sys.executable, str(script_path)],
        check=True
    )


print("MongoDB Load Process Completed Successfully")
