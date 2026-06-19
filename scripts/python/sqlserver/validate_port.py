import sys
import socket
import logging
import configparser
from pathlib import Path

# ============================================================
# Logging
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

LOGGER = logging.getLogger(__name__)

# ============================================================
# Configuration
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[3]

CONFIG_FILE = PROJECT_ROOT / "config" / "sqlserver.conf"


def load_configuration():

    if not CONFIG_FILE.exists():
        raise FileNotFoundError(
            f"Configuration file not found: {CONFIG_FILE}"
        )

    config = configparser.ConfigParser()

    config.read(CONFIG_FILE)

    if "sqlserver" not in config:
        raise ValueError(
            "Missing [sqlserver] section"
        )

    return config


def validate_port(host, port):

    LOGGER.info(
        "Host : %s",
        host
    )

    LOGGER.info(
        "Port : %s",
        port
    )

    try:

        with socket.create_connection(
            (host, int(port)),
            timeout=10
        ):

            LOGGER.info(
                "[PASS] TCP Connectivity Successful"
            )

            LOGGER.info(
                "[PASS] SQL Server Listener Reachable"
            )

            return True

    except Exception as exc:

        LOGGER.error(
            "[FAIL] TCP Connectivity Failed"
        )

        LOGGER.error(
            "%s",
            exc
        )

        return False


def main():

    try:

        config = load_configuration()

        host = config["sqlserver"].get(
            "SERVER",
            "localhost"
        )

        port = config["sqlserver"]["PORT"]

        LOGGER.info(
            "=================================================="
        )

        LOGGER.info(
            "SQL SERVER PORT VALIDATION"
        )

        LOGGER.info(
            "=================================================="
        )

        if validate_port(
            host,
            port
        ):

            LOGGER.info(
                "=================================================="
            )

            LOGGER.info(
                "PORT VALIDATION PASSED"
            )

            LOGGER.info(
                "=================================================="
            )

            sys.exit(0)

        LOGGER.error(
            "=================================================="
        )

        LOGGER.error(
            "PORT VALIDATION FAILED"
        )

        LOGGER.error(
            "=================================================="
        )

        sys.exit(1)

    except Exception as exc:

        LOGGER.exception(
            "Port validation failed: %s",
            exc
        )

        sys.exit(1)


if __name__ == "__main__":
    main()