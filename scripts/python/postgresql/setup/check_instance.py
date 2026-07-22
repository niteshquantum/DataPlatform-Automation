from pathlib import Path
import socket
import sys

import psycopg2

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config


def is_port_open(host, port):
    try:
        with socket.create_connection((host, port), timeout=2):
            return True
    except OSError:
        return False


def check_instance():
    config = load_database_config("postgresql")

    host = config["POSTGRESQL_HOST"]
    port = int(config["POSTGRESQL_PORT"])
    user = config["POSTGRESQL_USER"]
    password = config["POSTGRESQL_PASSWORD"]

    print("=" * 60)
    print("CHECKING POSTGRESQL INSTANCE")
    print("=" * 60)
    print(f"Host : {host}")
    print(f"Port : {port}")
    print()

    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            database="postgres",
            user=user,
            password=password,
            connect_timeout=5,
        )
        cursor = connection.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        cursor.close()
        connection.close()

        print(f"Instance detected : PostgreSQL on {host}:{port}")
        print(f"Version           : {version}")
        print()
        print("INSTANCE_STATE=INSTANCE_RUNNING_AND_USABLE")
        return "INSTANCE_RUNNING_AND_USABLE"

    except psycopg2.OperationalError as e:
        print(f"Instance not reachable : {e}")
        print()

        root = Path(__file__).resolve().parents[4]
        data_dir = root / "databases" / "postgresql" / "data"

        if data_dir.exists() and (data_dir / "PG_VERSION").exists():
            print("INSTANCE_STATE=INSTANCE_INSTALLED_BUT_STOPPED")
            return "INSTANCE_INSTALLED_BUT_STOPPED"

        if is_port_open(host, port):
            print("INSTANCE_STATE=PORT_OCCUPIED_BY_NON_POSTGRESQL")
            return "PORT_OCCUPIED_BY_NON_POSTGRESQL"

        print("INSTANCE_STATE=NO_INSTANCE")
        return "NO_INSTANCE"

    except Exception as e:
        print(f"Instance check failed : {e}")
        print()
        print("INSTANCE_STATE=NO_INSTANCE")
        return "NO_INSTANCE"


if __name__ == "__main__":
    try:
        state = check_instance()
        sys.exit(0 if state == "INSTANCE_RUNNING_AND_USABLE" else 1)
    except Exception as e:
        print(f"\nERROR : {e}")
        sys.exit(1)
