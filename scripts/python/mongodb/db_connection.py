from pymongo import MongoClient
from pathlib import Path
import platform

ROOT_DIR = Path(__file__).resolve().parents[3]

if platform.system() == "Windows":
    CONFIG_FILE = ROOT_DIR / "config" / "windows" / "mongodb.conf"
else:
    CONFIG_FILE = ROOT_DIR / "config" / "ubuntu" / "mongodb.conf"


def read_config():

    config = {}

    with open(CONFIG_FILE) as f:

        for line in f:

            line = line.strip()

            if line and "=" in line:

                key, value = line.split("=", 1)

                config[key.strip()] = value.strip()

    return config


def get_db():

    config = read_config()

    uri = (
        f"mongodb://"
        f"{config['MONGODB_HOST']}:"
        f"{config['MONGODB_PORT']}"
    )

    client = MongoClient(uri)

    return client[config["MONGODB_DATABASE"]]