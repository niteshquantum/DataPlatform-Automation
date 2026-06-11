import socket
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]

config = {}

with open(ROOT / "config" / "mysql.conf") as f:
    for line in f:
        if "=" in line:
            key, value = line.strip().split("=", 1)
            config[key] = value

port = int(config["MYSQL_PORT"])

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

result = sock.connect_ex(("127.0.0.1", port))

sock.close()

if result != 0:

    print()
    print("=" * 50)
    print("PORT VALIDATION FAILED")
    print("=" * 50)
    print(f"Port {port} is not listening")
    print("=" * 50)

    exit(1)

print()
print("=" * 50)
print("PORT VALIDATION SUCCESS")
print("=" * 50)
print(f"Configured Port : {port}")
print("Status          : LISTENING")
print("=" * 50)