import pandas as pd
from .db import get_connection
from .config import OUTPUTS_DIR

PRIORITY_MAP = {
    "low": 1,
    "medium": 2,
    "high": 3
}

def build_ofi():
    out_dir = OUTPUTS_DIR / "ofi"
    out_dir.mkdir(parents=True, exist_ok=True)

    conn = get_connection()
    try:
        cases = pd.read_sql("SELECT * FROM cases;", conn)
        refunds = pd.read_sql("SELECT * FROM refunds;", conn)
        timeline = pd.read_sql("SELECT * FROM case_timeline;", conn)
    finally:
        conn.close()

    # ---------- BASE PREP ----------
    cases["priority_score"] = cases["priority"].str.lower().map(PRIORITY_MAP).fillna(1)

    cases["escalation_score"] = cases["escalated_flag"] * 2
    cases["reopen_score"] = cases["reopened_flag"] * 1.5
    cases["delay_score"] = cases["delay_minutes"] / 60
    cases["resolution_score"] = cases["resolution_minutes"] / 120

    # ---------- REFUND IMPACT ----------
    refund_agg = (
        refunds.groupby("case_id")["refund_amount_eur"]
        .sum()
        .reset_index()
        .rename(columns={"refund_amount_eur": "refund_eur"})
    )

    cases = cases.merge(refund_agg, on="case_id", how="left")
    cases["refund_eur"] = cases["refund_eur"].fillna(0)
    cases["refund_score"] = cases["refund_eur"] / 20

    # ---------- TOUCHES ----------
    touches = (
        timeline.groupby("case_id")
        .size()
        .reset_index(name="touch_count")
    )

    cases = cases.merge(touches, on="case_id", how="left")
    cases["touch_count"] = cases["touch_count"].fillna(0)
    cases["touch_score"] = cases["touch_count"] * 0.5

    # ---------- FINAL OFI ----------
    cases["OFI"] = (
        cases["priority_score"]
        + cases["escalation_score"]
        + cases["reopen_score"]
        + cases["delay_score"]
        + cases["resolution_score"]
        + cases["refund_score"]
        + cases["touch_score"]
    )

    # ---------- OUTPUTS ----------
    cases.sort_values("OFI", ascending=False).to_csv(
        out_dir / "ofi_case_scores.csv", index=False
    )

    cases.sort_values("OFI", ascending=False).head(50).to_csv(
        out_dir / "top_50_cases.csv", index=False
    )

    customer_ofi = (
        cases.groupby("customer_id")["OFI"]
        .mean()
        .reset_index()
        .sort_values("OFI", ascending=False)
    )

    customer_ofi.to_csv(
        out_dir / "high_friction_customers.csv", index=False
    )

    print("OFI built successfully ✅")
