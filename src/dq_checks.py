import pandas as pd
from .db import get_connection
from .config import OUTPUTS_DIR
from .extract import TABLES


def run_dq_checks():
    out_dir = OUTPUTS_DIR / 'dq'
    out_dir.mkdir(parents=True, exist_ok=True)

    conn = get_connection()
    try:
        # 1) Row counts
        row_counts = []
        for t in TABLES:
            df = pd.read_sql('SELECT * FROM {};'.format(t), conn)
            row_counts.append({'table': t, 'rows': len(df), 'cols': df.shape[1]})

        pd.DataFrame(row_counts).sort_values('table').to_csv(out_dir / 'row_counts.csv', index=False)
        print('[dq] saved outputs/dq/row_counts.csv')

        # 2) Missing values
        missing_rows = []
        for t in TABLES:
            df = pd.read_sql('SELECT * FROM {};'.format(t), conn)
            miss = df.isna().sum()
            miss = miss[miss > 0]
            for col, cnt in miss.items():
                missing_rows.append({'table': t, 'column': col, 'missing_count': int(cnt)})

        pd.DataFrame(missing_rows).sort_values(['table', 'missing_count'], ascending=[True, False]) \
            .to_csv(out_dir / 'missing_values.csv', index=False)
        print('[dq] saved outputs/dq/missing_values.csv')

        # 3) Duplicates
        dup_rows = []
        for t in TABLES:
            df = pd.read_sql('SELECT * FROM {};'.format(t), conn)

            # Full-row duplicates
            dup_rows.append({
                'table': t,
                'check': 'full_row_duplicates',
                'count': int(df.duplicated().sum())
            })

            # ID-like columns duplicates
            id_like = [c for c in df.columns if c.lower() == 'id' or c.lower().endswith('_id')]
            for col in id_like[:6]:
                dup_rows.append({
                    'table': t,
                    'check': f'duplicate_in_{col}',
                    'count': int(df[col].duplicated().sum())
                })

        pd.DataFrame(dup_rows).sort_values(['table', 'count'], ascending=[True, False]) \
            .to_csv(out_dir / 'duplicates.csv', index=False)
        print('[dq] saved outputs/dq/duplicates.csv')

    finally:
        conn.close()

    print('Done ✅')
