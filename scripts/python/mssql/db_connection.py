from pathlib import Path
import pyodbc

ROOT = Path(__file__).resolve().parents[3]

config = {}

with open(ROOT / "config" / "windows" / "mssql.conf") as f:
    for line in f:
        if "=" in line:
            k, v = line.strip().split("=", 1)
            config[k] = v

def get_connection():

    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={config['MSSQL_HOST']},{config['MSSQL_PORT']};"
        f"DATABASE={config['MSSQL_DB']};"
        f"UID={config['MSSQL_USER']};"
        f"PWD={config['MSSQL_PASSWORD']};"
        f"Encrypt=yes;"
        f"TrustServerCertificate=yes;"
    )

    return conn