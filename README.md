# Operational Friction Index (OFI)

This project turns operational + customer support data into actionable insights by computing an **Operational Friction Index (OFI)**.

OFI quantifies how costly / problematic certain cases, customers, and time periods are using operational signals such as priority, escalations, reopens, delays, resolution time, refunds, and interaction volume (timeline events).

---

## Data Sources (MySQL tables)

- customers
- cases
- case_timeline
- agents
- products
- issue_catalog
- refunds
- calendar

---

## Pipeline (what the code does)

1. **Extract**
   - Pulls MySQL tables and exports them to CSV for transparency and debugging.

2. **Data Quality Checks**
   - Missing values
   - Duplicates
   - Row counts

3. **FK Integrity Checks**
   - Orphan detection across relationships (0 orphans in this dataset)

4. **OFI Scoring**
   - Generates case-level OFI scores
   - Exports Top 50 problematic cases
   - Ranks high-friction customers

5. **Trends & Segmentation**
   - Weekly + monthly friction trends
   - Severity/priority trend analysis
   - Customer tier segmentation

6. **Reports**
   - Creates a lightweight project report + summary status

---

## OFI logic (high level)

Case-level OFI uses:
- **Priority weight** (low/medium/high)
- **Escalation penalty**
- **Reopen penalty**
- **Delay penalty** (delay_minutes)
- **Resolution time penalty** (resolution_minutes)
- **Refund impact** (refund_amount_eur)
- **Touches penalty** (count of timeline events)

---

## Outputs (Power BI ready)

Generated in `outputs/ofi/`:

- `ofi_case_scores.csv`
- `top_50_cases.csv`
- `high_friction_customers.csv`
- `customer_tiers.csv`
- `weekly_friction_trend.csv`
- `monthly_friction_trend.csv`
- `severity_trend.csv`

Reports:
- `outputs/reports/project_report.txt`
- `outputs/reports/ofi_summary.csv`

---

## How to run

### 1) Create `.env` in the project root

```env
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=YOUR_PASSWORD
MYSQL_DATABASE=operational_friction_index
