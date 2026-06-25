from scripts.python.common.config_loader import load_database_config
import mysql.connector

config = load_database_config("mysql")


def get_connection():
    return mysql.connector.connect(
        host=config["MYSQL_HOST"],
        port=int(config["MYSQL_PORT"]),
        user=config["MYSQL_USER"],
        password=config["MYSQL_PASSWORD"],
        database=config["MYSQL_DB"]
    )