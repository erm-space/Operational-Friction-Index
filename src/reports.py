from pathlib import Path
import pandas as pd
from .config import OUTPUTS_DIR

def generate_reports():
    reports_dir = OUTPUTS_DIR / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    dq_dir = OUTPUTS_DIR / "dq"
    fk_dir = OUTPUTS_DIR / "fk"
    ofi_dir = OUTPUTS_DIR / "ofi"

    lines = []
    lines.append("OPERATIONAL FRICTION INDEX (OFI) - PROJECT REPORT")
    lines.append("--------------------------------------------------")

    # DQ
    row_counts_path = dq_dir / "row_counts.csv"
    missing_path = dq_dir / "missing_values.csv"
    duplicates_path = dq_dir / "duplicates.csv"

    if row_counts_path.exists():
        rc = pd.read_csv(row_counts_path)
        lines.append(f"DQ: tables checked = {len(rc)}")
        lines.append(f"DQ: total rows across tables = {int(rc['rows'].sum()):,}")
    else:
        lines.append("DQ: row_counts.csv not found")

    if missing_path.exists():
        mv = pd.read_csv(missing_path)
        lines.append(f"DQ: missing-value findings = {len(mv)}")
    else:
        lines.append("DQ: missing_values.csv not found")

    if duplicates_path.exists():
        du = pd.read_csv(duplicates_path)
        lines.append(f"DQ: duplicate-check rows = {len(du)}")
    else:
        lines.append("DQ: duplicates.csv not found")

    # FK
    fk_path = fk_dir / "fk_orphans_summary.csv"
    if fk_path.exists():
        fk = pd.read_csv(fk_path)
        total_orphans = int(fk["orphan_count"].sum())
        lines.append(f"FK: rules checked = {len(fk)}")
        lines.append(f"FK: total orphans = {total_orphans}")
    else:
        lines.append("FK: fk_orphans_summary.csv not found")

    # OFI
    case_scores_path = ofi_dir / "ofi_case_scores.csv"
    if case_scores_path.exists():
        ofi_cases = pd.read_csv(case_scores_path)
        if "OFI" in ofi_cases.columns:
            lines.append(f"OFI: cases scored = {len(ofi_cases):,}")
            lines.append(f"OFI: avg OFI = {ofi_cases['OFI'].mean():.2f}")
            lines.append(f"OFI: max OFI = {ofi_cases['OFI'].max():.2f}")
        else:
            lines.append("OFI: OFI column missing in ofi_case_scores.csv")
    else:
        lines.append("OFI: ofi_case_scores.csv not found")

    # Save report text
    report_txt = reports_dir / "project_report.txt"
    report_txt.write_text("\n".join(lines), encoding="utf-8")
    print(f"[reports] saved {report_txt}")

    # Save summary CSV (quick status)
    summary = [
        {"metric": "dq_row_counts_exists", "value": int(row_counts_path.exists())},
        {"metric": "dq_missing_values_exists", "value": int(missing_path.exists())},
        {"metric": "dq_duplicates_exists", "value": int(duplicates_path.exists())},
        {"metric": "fk_summary_exists", "value": int(fk_path.exists())},
        {"metric": "ofi_case_scores_exists", "value": int(case_scores_path.exists())},
    ]
    pd.DataFrame(summary).to_csv(reports_dir / "ofi_summary.csv", index=False)
    print("[reports] saved outputs/reports/ofi_summary.csv")
    print("Done ✅")
