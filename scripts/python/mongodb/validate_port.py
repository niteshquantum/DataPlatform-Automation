import socket
from db_connection import read_config

config = read_config()

HOST = config["MONGODB_HOST"]
PORT = int(config["MONGODB_PORT"])

try:

    socket.create_connection((HOST, PORT), timeout=5)

    print(f"MongoDB is running on port {PORT}")

except:

    print(f"MongoDB is NOT running on port {PORT}")