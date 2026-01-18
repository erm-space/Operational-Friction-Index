import os
from pathlib import Path

import pandas as pd
import mysql.connector
from dotenv import load_dotenv

# Load .env
env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path, override=True)

host = os.getenv("MYSQL_HOST") or "127.0.0.1"
port = int(os.getenv("MYSQL_PORT") or 3306)
user = os.getenv("MYSQL_USER") or "root"
password = os.getenv("MYSQL_PASSWORD")
database = os.getenv("MYSQL_DATABASE")

out_dir = Path(__file__).resolve().parent / "outputs"
out_dir.mkdir(exist_ok=True)

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

conn = mysql.connector.connect(
    host=host, port=port, user=user, password=password, database=database
)

# ---------- 1) Row counts ----------
row_counts = []
for t in tables:
    df = pd.read_sql(f"SELECT * FROM `{t}`;", conn)
    row_counts.append({"table": t, "rows": len(df), "cols": df.shape[1]})

row_counts_df = pd.DataFrame(row_counts).sort_values("table")
row_counts_df.to_csv(out_dir / "dq_row_counts.csv", index=False)
print("Saved outputs/dq_row_counts.csv")

# ---------- 2) Missing values ----------
missing_rows = []
for t in tables:
    df = pd.read_sql(f"SELECT * FROM `{t}`;", conn)
    miss = df.isna().sum()
    miss = miss[miss > 0]
    for col, cnt in miss.items():
        missing_rows.append({"table": t, "column": col, "missing_count": int(cnt)})

missing_df = pd.DataFrame(missing_rows).sort_values(["table", "missing_count"], ascending=[True, False])
missing_df.to_csv(out_dir / "dq_missing_values.csv", index=False)
print("Saved outputs/dq_missing_values.csv")

# ---------- 3) Duplicate checks (simple) ----------
# We'll check full-row duplicates + likely ID columns if they exist.
dup_rows = []
for t in tables:
    df = pd.read_sql(f"SELECT * FROM `{t}`;", conn)

    full_dup = int(df.duplicated().sum())
    dup_rows.append({"table": t, "check": "full_row_duplicates", "count": full_dup})

    # common ID patterns
    possible_id_cols = [c for c in df.columns if c.lower() in {"id", f"{t[:-1]}_id", f"{t}_id"} or c.lower().endswith("_id")]
    for col in possible_id_cols[:5]:  # limit to avoid noise
        dup_count = int(df[col].duplicated().sum())
        dup_rows.append({"table": t, "check": f"duplicate_in_{col}", "count": dup_count})

dups_df = pd.DataFrame(dup_rows).sort_values(["table", "count"], ascending=[True, False])
dups_df.to_csv(out_dir / "dq_duplicates.csv", index=False)
print("Saved outputs/dq_duplicates.csv")

conn.close()
print("Done ✅")