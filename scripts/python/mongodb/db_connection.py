from pymongo import MongoClient
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[3]

CONFIG_FILE = ROOT_DIR / "config" / "mongodb.conf"

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

    uri = f"mongodb://{config['MONGODB_HOST']}:{config['MONGODB_PORT']}"

    client = MongoClient(uri)

    db = client[config["MONGODB_DATABASE"]]

    return db

