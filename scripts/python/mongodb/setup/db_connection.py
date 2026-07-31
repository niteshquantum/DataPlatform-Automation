"""MongoDB connection helpers with authentication and retry support."""

from __future__ import annotations

import sys
import time
from pathlib import Path

from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, PyMongoError

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.mongodb.setup.config_loader import load_config

config = load_config()

HOST = config["MONGODB_HOST"]
PORT = int(config["MONGODB_PORT"])
DATABASE = config["MONGODB_DATABASE"]


def _client(authenticated=False, username=None, password=None):
    auth_source = "admin"
    common = {
        "host": HOST,
        "port": PORT,
        "serverSelectionTimeoutMS": 10000,
        "socketTimeoutMS": 10000,
        "connectTimeoutMS": 5000,
    }
    if authenticated and username and password:
        common.update(
            {
                "username": username,
                "password": password,
                "authSource": auth_source,
            }
        )
    return MongoClient(**common)


def get_client(authenticated=False, username=None, password=None):
    return _client(authenticated=authenticated, username=username, password=password)


def wait_for_client(authenticated=False, username=None, password=None, max_attempts=30):
    last_exception = None
    for attempt in range(1, max_attempts + 1):
        try:
            client = _client(authenticated=authenticated, username=username, password=password)
            client.admin.command("ping")
            return client
        except PyMongoError as exc:
            last_exception = exc
            if attempt < max_attempts:
                time.sleep(1)
    raise ConnectionFailure(
        f"MongoDB at {HOST}:{PORT} is not available after {max_attempts} attempts."
    ) from last_exception


def get_db(authenticated=False, username=None, password=None):
    client = wait_for_client(authenticated=authenticated, username=username, password=password)
    return client.get_database(DATABASE)