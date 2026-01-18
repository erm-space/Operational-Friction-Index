from src.extract import extract_all
from src.dq_checks import run_dq_checks
from src.fk_checks import run_fk_checks
from src.ofi_build import build_ofi
from src.ofi_trends import build_trends_and_tiers
from src.reports import generate_reports

if __name__ == "__main__":
    extract_all()
    run_dq_checks()
    run_fk_checks()
    build_ofi()
    build_trends_and_tiers()
    generate_reports()
    print("\nALL DONE ✅")
