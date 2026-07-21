import socket
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config


def check_instance():
    config = load_database_config("mssql")

    host = config["MSSQL_HOST"]
    port = int(config["MSSQL_PORT"])
    instance = config.get("MSSQL_INSTANCE", "MSSQLSERVER")

    print("=" * 60)
    print("CHECKING MSSQL INSTANCE")
    print("=" * 60)
    print(f"Host     : {host}")
    print(f"Port     : {port}")
    print(f"Instance : {instance}")
    print()

    service_name = (
        "MSSQLSERVER"
        if instance == "MSSQLSERVER"
        else f"MSSQL${instance}"
    )

    try:
        result = subprocess.run(
            ["powershell", "-Command", f"Get-Service -Name '{service_name}' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        service_status = result.stdout.strip()

        if result.returncode != 0 or not service_status:
            print(f"Service not found : {service_name}")
            print()
            print("INSTANCE_STATE=NO_INSTANCE")
            return "NO_INSTANCE"

        if service_status != "Running":
            print(f"Service status : {service_status}")
            print()
            print("INSTANCE_STATE=INSTANCE_INSTALLED_BUT_STOPPED")
            return "INSTANCE_INSTALLED_BUT_STOPPED"

        print(f"Service status : {service_status}")

    except Exception as e:
        print(f"Service check failed : {e}")
        print()
        print("INSTANCE_STATE=NO_INSTANCE")
        return "NO_INSTANCE"

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    result = sock.connect_ex((host, port))
    sock.close()

    if result != 0:
        print(f"Port not listening : {host}:{port}")
        print()
        print("INSTANCE_STATE=NO_INSTANCE")
        return "NO_INSTANCE"

    print(f"Port listening     : {host}:{port}")
    print()
    print("INSTANCE_STATE=INSTANCE_RUNNING_AND_USABLE")
    return "INSTANCE_RUNNING_AND_USABLE"


if __name__ == "__main__":
    try:
        state = check_instance()
        sys.exit(0 if state == "INSTANCE_RUNNING_AND_USABLE" else 1)
    except Exception as e:
        print(f"\nERROR : {e}")
        sys.exit(1)
