import socket
from db_connection import load_config


def check_port():

    config = load_config()

    host = config.get(
        "POSTGRESQL_HOST",
        "localhost"
    )

    port = int(
        config.get(
            "POSTGRESQL_PORT",
            "5432"
        )
    )

    sock = socket.socket(
        socket.AF_INET,
        socket.SOCK_STREAM
    )

    result = sock.connect_ex(
        (host, port)
    )

    sock.close()

    if result == 0:
        print(
            f"SUCCESS : Port {port} is open"
        )
        return True

    print(
        f"FAILED : Port {port} is closed"
    )

    return False


if __name__ == "__main__":
    check_port()