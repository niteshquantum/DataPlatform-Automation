from pathlib import Path
import sys

import pyodbc

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.common.config_loader import load_database_config

config = load_database_config("mssql")


def get_connection(database=None):

    drivers = pyodbc.drivers()

    if "ODBC Driver 18 for SQL Server" in drivers:
        driver = "ODBC Driver 18 for SQL Server"

    elif "ODBC Driver 17 for SQL Server" in drivers:
        driver = "ODBC Driver 17 for SQL Server"

    else:
        raise RuntimeError(
            "No supported SQL Server ODBC driver found."
        )

    return pyodbc.connect(
        f"DRIVER={{{driver}}};"
        f"SERVER={config['MSSQL_HOST']},{config['MSSQL_PORT']};"
        f"DATABASE={database if database else config['MSSQL_DB']};"
        f"UID={config['MSSQL_USER']};"
        f"PWD={config['MSSQL_PASSWORD']};"
        "TrustServerCertificate=yes;",
        timeout=30
    )