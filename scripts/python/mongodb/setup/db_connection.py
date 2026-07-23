
from pymongo import MongoClient
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.mongodb.setup.config_loader import load_config
config = load_config()


def get_client():
    options = {}
    if config.get("MONGODB_AUTHORIZATION_ENABLED", "false").lower() == "true":
        options = {
            "username": config["RBAC_ADMIN_USERNAME"],
            "password": config["RBAC_ADMIN_PASSWORD"],
            "authSource": "admin",
        }
    return MongoClient(config["MONGODB_HOST"], int(config["MONGODB_PORT"]), **options)

def get_db():

    client = get_client()

    return client[config["MONGODB_DATABASE"]]
