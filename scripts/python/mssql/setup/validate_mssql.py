import sys
from pathlib import Path

import pyodbc

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config


def validate_mssql():

    config = load_database_config("mssql")

    host = config["MSSQL_HOST"]
    port = int(config["MSSQL_PORT"])
    database = config["MSSQL_DB"]
    user = config["MSSQL_USER"]
    password = config["MSSQL_PASSWORD"]

    print("=" * 60)
    print("VALIDATING MSSQL")
    print("=" * 60)

    drivers = pyodbc.drivers()

    if "ODBC Driver 18 for SQL Server" in drivers:
        driver = "ODBC Driver 18 for SQL Server"
    elif "ODBC Driver 17 for SQL Server" in drivers:
        driver = "ODBC Driver 17 for SQL Server"
    else:
        raise RuntimeError("No supported SQL Server ODBC Driver found.")

    connection = pyodbc.connect(
        f"DRIVER={{{driver}}};"
        f"SERVER={host},{port};"
        f"DATABASE={database};"
        f"UID={user};"
        f"PWD={password};"
        "TrustServerCertificate=yes;"
    )

    cursor = connection.cursor()

    cursor.execute("SELECT DB_NAME();")
    current_database = cursor.fetchone()[0]

    cursor.execute("SELECT CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(100));")
    version = cursor.fetchone()[0]

    cursor.execute("SELECT local_tcp_port FROM sys.dm_exec_connections WHERE session_id = @@SPID;")
    current_port = cursor.fetchone()[0]

    print(f"Database : {current_database}")
    print(f"Port     : {current_port}")
    print(f"Version  : {version}")

    cursor.close()
    connection.close()

    print()
    print("MSSQL validation successful.")


if __name__ == "__main__":

    try:

        validate_mssql()

    except Exception as error:

        print(f"\nERROR : {error}")

        sys.exit(1)