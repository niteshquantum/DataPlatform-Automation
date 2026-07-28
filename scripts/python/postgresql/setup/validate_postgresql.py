import sys
import json
import platform
import subprocess
from pathlib import Path

import psycopg2

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config


def validate_postgresql():

    config = load_database_config("postgresql")

    # Windows validation consumes the exact target emitted only after
    # start_postgresql has started or safely reused the managed service.
    # This prevents a config-only validation from silently reaching a system
    # PostgreSQL listener.
    if platform.system() == "Windows":
        runtime_target = ROOT / "outputs" / "runtime" / "postgresql_windows_target.json"
        if not runtime_target.is_file():
            raise RuntimeError("PostgreSQL runtime target is missing; run start_postgresql before validation.")
        target = json.loads(runtime_target.read_text(encoding="utf-8-sig"))
        expected = {
            "host": config["POSTGRESQL_HOST"],
            "port": int(config["POSTGRESQL_PORT"]),
            "service_name": config["POSTGRESQL_SERVICE_NAME"],
            "data_directory": config["POSTGRESQL_DATA_DIR"],
        }
        if any(target.get(key) != value for key, value in expected.items()):
            raise RuntimeError("PostgreSQL runtime target does not match the configured automation target.")
        pg_ctl = Path(config["POSTGRESQL_BIN_DIR"]) / "pg_ctl.exe"
        status = subprocess.run(
            [str(pg_ctl), "status", "-D", config["POSTGRESQL_DATA_DIR"]],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if status.returncode != 0:
            raise RuntimeError("The configured PostgreSQL data directory is not running; refusing to validate another listener.")
        host, port = target["host"], int(target["port"])
    else:
        host, port = config["POSTGRESQL_HOST"], int(config["POSTGRESQL_PORT"])

    user = config["POSTGRESQL_USER"]
    password = config["POSTGRESQL_PASSWORD"]

    print("=" * 60)
    print("VALIDATING POSTGRESQL INSTANCE")
    print("=" * 60)

    connection = psycopg2.connect(
        host=host,
        port=port,
        database="postgres",
        user=user,
        password=password
    )

    cursor = connection.cursor()
    cursor.execute("SELECT current_database();")
    current_database = cursor.fetchone()[0]

    cursor.execute("SHOW port;")
    current_port = cursor.fetchone()[0]

    cursor.execute("SELECT version();")
    version = cursor.fetchone()[0]

    print(f"Database : {current_database}")
    print(f"Port     : {current_port}")
    print(f"Version  : {version}")

    cursor.close()
    connection.close()

    print()
    print("PostgreSQL validation successful.")


if __name__ == "__main__":

    try:
        validate_postgresql()

    except Exception as error:
        print(f"\nERROR : {error}")
        sys.exit(1)
