import os
from pathlib import Path

import mysql.connector
from dotenv import load_dotenv


# 1) Force-load .env from the SAME folder as this file
env_path = Path(__file__).resolve().parent / ".env"
print("Using .env at:", env_path)

load_dotenv(dotenv_path=env_path, override=True)


# 2) Print what we loaded (debug)
print("ENV PATH CHECK")
print("MYSQL_HOST =", repr(os.getenv("MYSQL_HOST")))
print("MYSQL_PORT =", repr(os.getenv("MYSQL_PORT")))
print("MYSQL_USER =", repr(os.getenv("MYSQL_USER")))
print("MYSQL_DATABASE =", repr(os.getenv("MYSQL_DATABASE")))


# 3) Read config (with safe defaults for host/port)
host = os.getenv("MYSQL_HOST") or "127.0.0.1"
port = int(os.getenv("MYSQL_PORT") or 3306)
user = os.getenv("MYSQL_USER") or "root"
password = os.getenv("MYSQL_PASSWORD")
database = os.getenv("MYSQL_DATABASE")

if not password:
    raise ValueError("MYSQL_PASSWORD is missing. Check your .env file.")


# 4) Connect + test
try:
    conn = mysql.connector.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        database=database,
    )
    cursor = conn.cursor()

    cursor.execute("SELECT DATABASE();")
    print("Connected to database:", cursor.fetchone()[0])

    cursor.execute("SHOW TABLES;")
    tables = cursor.fetchall()

    print("Tables in database:")
    for (t,) in tables:
        print("-", t)

    cursor.close()
    conn.close()
    print("Connection successful and closed.")

except mysql.connector.Error as e:
    print("Connection failed:", e)
