from pymongo import MongoClient

from config_loader import load_config

config = load_config()


def get_client():

    uri = (
        f"mongodb://"
        f"{config['MONGODB_HOST']}:"
        f"{config['MONGODB_PORT']}"
    )

    return MongoClient(uri)


def get_db():

    client = get_client()

    return client[config["MONGODB_DATABASE"]]