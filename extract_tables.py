import os
from pathlib import Path

import pandas as pd
import mysql.connector
from dotenv import load_dotenv

# Load .env from the same folder as this file
env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path, override=True)

host = os.getenv("MYSQL_HOST") or "127.0.0.1"
port = int(os.getenv("MYSQL_PORT") or 3306)
user = os.getenv("MYSQL_USER") or "root"
password = os.getenv("MYSQL_PASSWORD")
database = os.getenv("MYSQL_DATABASE")

tables = [
    "agents",
    "calendar",
    "case_timeline",
    "cases",
    "customers",
    "issue_catalog",
    "products",
    "refunds",
]

# Create outputs folder
out_dir = Path(__file__).resolve().parent / "outputs"
out_dir.mkdir(exist_ok=True)

conn = mysql.connector.connect(
    host=host,
    port=port,
    user=user,
    password=password,
    database=database,
)

try:
    for t in tables:
        query = "SELECT * FROM `{}`;".format(t)  # safer than f-strings for beginners
        df = pd.read_sql(query, conn)

        out_path = out_dir / f"{t}.csv"
        df.to_csv(out_path, index=False)

        print(f"Saved {out_path} | rows={len(df):,} cols={df.shape[1]}")
finally:
    conn.close()

print("Done ✅")