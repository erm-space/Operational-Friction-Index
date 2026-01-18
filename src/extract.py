from pathlib import Path
import pandas as pd
from .db import get_connection
from .config import OUTPUTS_DIR

TABLES = [
    'agents',
    'calendar',
    'case_timeline',
    'cases',
    'customers',
    'issue_catalog',
    'products',
    'refunds',
]

def extract_all():
    out_dir = OUTPUTS_DIR / 'extracts'
    out_dir.mkdir(parents=True, exist_ok=True)

    conn = get_connection()
    try:
        for t in TABLES:
            query = 'SELECT * FROM {};'.format(t)
            df = pd.read_sql(query, conn)
            df.to_csv(out_dir / f'{t}.csv', index=False)
            print(f'[extract] saved {t}.csv | rows={len(df):,} cols={df.shape[1]}')
    finally:
        conn.close()
