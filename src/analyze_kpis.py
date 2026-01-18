import pandas as pd
from .db import get_connection
from .config import OUTPUTS_DIR

def build_kpis():
    out_dir = OUTPUTS_DIR / "analysis"
    out_dir.mkdir(parents=True, exist_ok=True)

    conn = get_connection()
    try:
        cases = pd.read_sql("SELECT * FROM cases;", conn)
        refunds = pd.read_sql("SELECT * FROM refunds;", conn)
    finally:
        conn.close()

    # KPI 1: cases by priority
    kpi_cases_priority = cases.groupby("priority").size().reset_index(name="case_count")
    kpi_cases_priority.to_csv(out_dir / "kpi_cases_by_priority.csv", index=False)

    # KPI 2: avg resolution by priority
    kpi_resolution = cases.groupby("priority")["resolution_minutes"].mean().reset_index()
    kpi_resolution.rename(columns={"resolution_minutes": "avg_resolution_minutes"}).to_csv(
        out_dir / "kpi_avg_resolution_by_priority.csv", index=False
    )

    # KPI 3: refunds totals (one-row table)
    kpi_refunds = pd.DataFrame([{
        "total_refund_eur": float(refunds["refund_amount_eur"].sum()),
        "refund_count": int(refunds["refund_id"].count())
    }])
    kpi_refunds.to_csv(out_dir / "kpi_refunds_summary.csv", index=False)

    print("KPIs saved ✅")
