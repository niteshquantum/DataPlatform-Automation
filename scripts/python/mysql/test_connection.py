from db_connection import get_connection

conn = get_connection()

print("MySQL Connected Successfully")

conn.close()