import pandas as pd
from .db import get_connection
from .config import OUTPUTS_DIR

def build_trends_and_tiers():
    out_dir = OUTPUTS_DIR / "ofi"
    out_dir.mkdir(parents=True, exist_ok=True)

    # Load OFI scores (already contains OFI and priority from your scoring step)
    ofi_cases = pd.read_csv(out_dir / "ofi_case_scores.csv")

    conn = get_connection()
    try:
        timeline = pd.read_sql("SELECT case_id, event_timestamp FROM case_timeline;", conn)
    finally:
        conn.close()

    timeline["event_timestamp"] = pd.to_datetime(timeline["event_timestamp"])

    # First timestamp per case = case start date
    first_event = (
        timeline.sort_values("event_timestamp")
        .groupby("case_id", as_index=False)
        .first()
        .rename(columns={"event_timestamp": "case_start_ts"})
    )

    df = ofi_cases.merge(first_event[["case_id", "case_start_ts"]], on="case_id", how="left")
    df["case_start_ts"] = pd.to_datetime(df["case_start_ts"])

    # WEEKLY trend
    df["week"] = df["case_start_ts"].dt.to_period("W").astype(str)
    weekly = df.groupby("week")["OFI"].mean().reset_index().sort_values("week")
    weekly.to_csv(out_dir / "weekly_friction_trend.csv", index=False)

    # MONTHLY trend
    df["month"] = df["case_start_ts"].dt.to_period("M").astype(str)
    monthly = df.groupby("month")["OFI"].mean().reset_index().sort_values("month")
    monthly.to_csv(out_dir / "monthly_friction_trend.csv", index=False)

    # Severity/priority trend
    if "priority" in df.columns:
        df["priority_clean"] = df["priority"].astype(str).str.lower()
        sev_trend = (
            df.groupby(["month", "priority_clean"])["OFI"]
            .mean()
            .reset_index()
            .sort_values(["month", "priority_clean"])
        )
        sev_trend.to_csv(out_dir / "severity_trend.csv", index=False)
    else:
        print("[warn] priority column not found in ofi_case_scores.csv -> skipping severity_trend.csv")

    # CUSTOMER TIERS (based on avg OFI)
    if "customer_id" in df.columns:
        customer_avg = df.groupby("customer_id")["OFI"].mean().reset_index()

        # qcut can fail if too many identical values -> add fallback
        try:
            customer_avg["tier"] = pd.qcut(
                customer_avg["OFI"], q=3,
                labels=["Low Friction", "Medium Friction", "High Friction"]
            )
        except Exception:
            # fallback using percentiles
            p33 = customer_avg["OFI"].quantile(0.33)
            p66 = customer_avg["OFI"].quantile(0.66)
            customer_avg["tier"] = customer_avg["OFI"].apply(
                lambda x: "Low Friction" if x <= p33 else ("Medium Friction" if x <= p66 else "High Friction")
            )

        customer_avg.sort_values("OFI", ascending=False).to_csv(out_dir / "customer_tiers.csv", index=False)
    else:
        print("[warn] customer_id not found -> skipping customer_tiers.csv")

    print("Trends + tiers saved ✅")
