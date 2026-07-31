from pathlib import Path
import sys

from pymongo import MongoClient

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from scripts.python.mongodb.setup.config_loader import load_config  # noqa: E402


def main():
    config = load_config()

    client = MongoClient(
        host=config["MONGODB_HOST"],
        port=int(config["MONGODB_PORT"]),
        username=config["RBAC_ADMIN_USERNAME"],
        password=config["RBAC_ADMIN_PASSWORD"],
        authSource="admin",
    )
    db = client[config["MONGODB_DATABASE"]]

    print("=" * 50)
    print("MONGODB INDEX VALIDATION")
    print("=" * 50)
    print("No custom MongoDB indexes are defined by the current repository.")
    print("Validating MongoDB default _id indexes for existing collections.")

    for collection_name in sorted(db.list_collection_names()):
        index_names = [
            index["name"]
            for index in db[collection_name].list_indexes()
        ]

        if "_id_" not in index_names:
            raise RuntimeError(
                f"Default _id index missing for collection: {collection_name}"
            )

        print(f"[OK] {collection_name}: _id_")

    print("=" * 50)
    print("MONGODB INDEX VALIDATION COMPLETED")
    print("=" * 50)

    client.close()


if __name__ == "__main__":
    main()
