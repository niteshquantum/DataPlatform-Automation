import os
import psycopg2
from configparser import ConfigParser


def get_project_root():
    return os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            ".."
        )
    )


def load_config():

    project_root = get_project_root()

    config_file = os.path.join(
        project_root,
        "config",
        "postgresql.conf"
    )

    if not os.path.exists(config_file):
        raise FileNotFoundError(
            f"Configuration file not found: {config_file}"
        )

    parser = ConfigParser()

    parser.read_string(
        "[POSTGRESQL]\n" +
        open(config_file).read()
    )

    return parser["POSTGRESQL"]


def get_connection():

    config = load_config()

    connection = psycopg2.connect(
        host=config.get("POSTGRESQL_HOST", "127.0.0.1"),
        port=config.get("POSTGRESQL_PORT", "5432"),
        database=config.get("POSTGRESQL_DATABASE", config.get("POSTGRESQL_DB")),
        user=config.get("POSTGRESQL_ADMIN_USER", config.get("POSTGRESQL_USER")),
        password=config.get("POSTGRESQL_ADMIN_PASSWORD", config.get("POSTGRESQL_PASSWORD", ""))
    )

    return connection