import pandas as pd
from .db import get_connection
from .config import OUTPUTS_DIR

FK_RULES = [
    ('cases', 'customer_id', 'customers', 'customer_id'),
    ('refunds', 'case_id', 'cases', 'case_id'),
    ('case_timeline', 'case_id', 'cases', 'case_id'),
    ('cases', 'agent_id', 'agents', 'agent_id'),
    ('cases', 'product_id', 'products', 'product_id'),
    ('cases', 'issue_id', 'issue_catalog', 'issue_id'),
]

def run_fk_checks():
    out_dir = OUTPUTS_DIR / 'fk'
    out_dir.mkdir(parents=True, exist_ok=True)

    conn = get_connection()
    results = []
    try:
        for child, fk, parent, pk in FK_RULES:
            q = f'''
            SELECT COUNT(*) AS orphan_count
            FROM {child} c
            LEFT JOIN {parent} p
              ON c.{fk} = p.{pk}
            WHERE c.{fk} IS NOT NULL
              AND p.{pk} IS NULL;
            '''
            orphan_count = int(pd.read_sql(q, conn)['orphan_count'].iloc[0])
            results.append({
                'child_table': child,
                'child_fk': fk,
                'parent_table': parent,
                'parent_pk': pk,
                'orphan_count': orphan_count
            })
            print(f'[fk] {child}.{fk} -> {parent}.{pk} | orphans={orphan_count}')

        pd.DataFrame(results).to_csv(out_dir / 'fk_orphans_summary.csv', index=False)
        print('[fk] saved outputs/fk/fk_orphans_summary.csv')

    finally:
        conn.close()

    print('Done ✅')
