from pathlib import Path
import sys
import socket
from pymongo import MongoClient
from pymongo.errors import PyMongoError

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.mongodb.setup.config_loader import load_config

config = load_config()

HOST = config["MONGODB_HOST"]
PORT = int(config["MONGODB_PORT"])
DB = config["MONGODB_DATABASE"]

PROJECT_MONGOD_BIN = ROOT / "databases" / "mongodb" / "server" / "bin" / "mongod.exe"
PROJECT_MONGOD_DATA = ROOT / "databases" / "mongodb" / "data"


def check():
    result = {
        "HOST": HOST,
        "PORT": str(PORT),
        "DATABASE": DB,
        "PROJECT_BINARIES_EXIST": "FALSE",
        "PROJECT_DATA_EXISTS": "FALSE",
        "TCP_OPEN": "FALSE",
        "MONGODB_AVAILABLE": "FALSE",
        "INSTANCE_STATE": "NO_INSTANCE",
        "ERROR": "None",
    }

    if PROJECT_MONGOD_BIN.exists():
        result["PROJECT_BINARIES_EXIST"] = "TRUE"

    if PROJECT_MONGOD_DATA.exists():
        result["PROJECT_DATA_EXISTS"] = "TRUE"

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)
    tcp_result = sock.connect_ex((HOST, PORT))
    sock.close()

    if tcp_result != 0:
        result["ERROR"] = f"Port {PORT} is not listening"
        if result["PROJECT_BINARIES_EXIST"] == "TRUE":
            result["INSTANCE_STATE"] = "INSTANCE_INSTALLED_BUT_STOPPED"
        else:
            result["INSTANCE_STATE"] = "NO_INSTANCE"
        return result

    result["TCP_OPEN"] = "TRUE"

    try:
        client = MongoClient(f"mongodb://{HOST}:{PORT}", serverSelectionTimeoutMS=2000)
        client.admin.command("ping")
        client.close()
        result["MONGODB_AVAILABLE"] = "TRUE"
    except PyMongoError as e:
        result["ERROR"] = str(e)
        result["INSTANCE_STATE"] = "PORT_OCCUPIED_BY_NON_MONGODB"
        return result

    result["INSTANCE_STATE"] = "INSTANCE_RUNNING_AND_USABLE"
    return result


if __name__ == "__main__":
    r = check()
    for k, v in r.items():
        print(f"{k}={v}")
