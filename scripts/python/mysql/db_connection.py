from pathlib import Path
import mysql.connector

ROOT = Path(__file__).resolve().parents[3]

config_file = ROOT / "config" / "mysql.conf"

config = {}

with open(config_file, "r") as f:
    for line in f:
        if "=" in line:
            key, value = line.strip().split("=", 1)
            config[key] = value

def get_connection():
    return mysql.connector.connect(
        # host="localhost",
        # host="127.0.0.1",
        host=config["MYSQL_HOST"],
        port=int(config["MYSQL_PORT"]),
        user=config["MYSQL_USER"],
        password=config["MYSQL_PASSWORD"],
        database=config["MYSQL_DB"]
    )