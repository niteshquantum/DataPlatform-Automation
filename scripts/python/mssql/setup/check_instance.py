import socket
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config


def _powershell(script, timeout=10):
    try:
        result = subprocess.run(
            ["powershell", "-Command", script],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.returncode, result.stdout.strip(), result.stderr.strip()
    except Exception as exc:
        return -1, "", str(exc)


def _get_service_image_path(service_name):
    try:
        result = subprocess.run(
            ["sc.exe", "qc", service_name],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode != 0:
            return None
        for line in result.stdout.splitlines():
            if "BINARY_PATH_NAME" in line:
                return line.split(":", 1)[1].strip()
        return None
    except Exception:
        return None


def _find_instance_id(instance):
    if instance == "MSSQLSERVER":
        return "MSSQLSERVER"

    ps_script = (
        "Get-ChildItem 'HKLM:\\SOFTWARE\\Microsoft\\Microsoft SQL Server' | "
        "ForEach-Object { "
        "  $id = $_.PSChildName; "
        "  $setup = Get-ItemProperty ($_.PSPath + '\\Setup') -ErrorAction SilentlyContinue; "
        f"  if ($setup -and $setup.InstanceName -eq '{instance}') {{ Write-Host $id }} "
        "}"
    )
    rc, out, _ = _powershell(ps_script)
    if rc != 0 or not out:
        return None
    return out.splitlines()[0].strip()


def _get_registry_image_path(instance_id):
    reg_path = (
        f"HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\{instance_id}\\Setup"
    )
    rc, out, _ = _powershell(
        f"Get-ItemProperty '{reg_path}' -ErrorAction SilentlyContinue "
        "| Select-Object -ExpandProperty ImagePath"
    )
    if rc != 0 or not out:
        return None
    return out


def _verify_project_managed_instance(instance):
    service_name = (
        "MSSQLSERVER"
        if instance == "MSSQLSERVER"
        else f"MSSQL${instance}"
    )

    image_path = _get_service_image_path(service_name)
    if not image_path or "sqlservr.exe" not in image_path.lower():
        return False

    instance_id = _find_instance_id(instance)
    if not instance_id:
        return False

    reg_image = _get_registry_image_path(instance_id)
    if not reg_image or "sqlservr.exe" not in reg_image.lower():
        return False

    return True


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
            ["powershell", "-Command",
             f"Get-Service -Name '{service_name}' -ErrorAction SilentlyContinue "
             "| Select-Object -ExpandProperty Status"],
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

        print(f"Service status : {service_status}")

    except Exception as e:
        print(f"Service check failed : {e}")
        print()
        print("INSTANCE_STATE=NO_INSTANCE")
        return "NO_INSTANCE"

    if not _verify_project_managed_instance(instance):
        print(
            f"Instance service '{service_name}' exists but does not match "
            f"project-managed '{instance}' installation."
        )
        print()
        print("INSTANCE_STATE=NO_INSTANCE")
        return "NO_INSTANCE"

    if service_status != "Running":
        print(f"Service status : {service_status}")
        print()
        print("INSTANCE_STATE=INSTANCE_INSTALLED_BUT_STOPPED")
        return "INSTANCE_INSTALLED_BUT_STOPPED"

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
