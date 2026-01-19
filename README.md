Operational Friction Index (OFI)
Overview

The Operational Friction Index (OFI) project transforms operational and customer support data into actionable business insights by quantifying how costly, delayed, and problematic support cases are.

OFI is a composite metric designed to surface:

High-risk cases

High-friction customers

Cost drivers across time, severity, and product groups

The project combines MySQL, Python, and Power BI to deliver an end-to-end analytics pipeline — from raw data extraction to executive-ready dashboards.

🔍 What is OFI?

The Operational Friction Index (OFI) assigns a weighted score to each case based on multiple operational signals, including:

Priority level

Escalations

Reopens

Delays

Resolution time

Refund impact

Interaction volume (timeline events)

This allows teams to quantify friction, not just observe it.

🗄️ Data Sources (MySQL)

The project uses a relational MySQL schema with the following tables:

customers

cases

case_timeline

agents

products

issue_catalog

refunds

calendar

All relationships are validated and enforced during processing.

⚙️ Data Pipeline (Python)
1️⃣ Extract

Pulls data from MySQL

Exports all tables to CSV for transparency and debugging

2️⃣ Data Quality Checks

Missing values

Duplicate records

Row count validation

Foreign key integrity checks

✅ 0 orphan records detected

3️⃣ OFI Scoring

Computes case-level OFI scores

Identifies:

Top 50 most problematic cases

High-friction customers

4️⃣ Trends & Segmentation

Weekly & monthly friction trends

Severity and priority trend analysis

Customer tier segmentation based on friction levels

5️⃣ Reporting

Generates lightweight text and CSV reports summarizing project outcomes

🧠 OFI Logic (High Level)

Each case receives an OFI score based on:

Priority weight (Low / Medium / High)

Escalation penalty

Reopen penalty

Delay penalty (delay_minutes)

Resolution time penalty (resolution_minutes)

Refund impact (refund_amount_eur)

Touches penalty (count of timeline events)

All components are combined into a single friction score per case.

📤 Outputs (Power BI Ready)

Generated under outputs/ofi/:

ofi_case_scores.csv

top_50_cases.csv

high_friction_customers.csv

customer_tiers.csv

weekly_friction_trend.csv

monthly_friction_trend.csv

severity_trend.csv

Reports

outputs/reports/project_report.txt

outputs/reports/ofi_summary.csv

These files are directly used in Power BI to build dashboards covering:

Escalations & risk analysis

Financial impact & cost drivers

Friction trends and operational performance

📊 Visualization Layer (Power BI)

Power BI dashboards are built on top of the generated outputs to provide:

Executive KPIs (refund cost, escalation rate, resolution time)

Severity-based risk analysis

Cost drivers by product group

Monthly refund trends

Operational insights and recommendations

▶️ How to Run the Project
1️⃣ Create a .env file in the project root
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=YOUR_PASSWORD
MYSQL_DATABASE=operational_friction_index

2️⃣ Run the Python pipeline
python main.py


Outputs will be generated automatically in the outputs/ directory.

🧰 Tech Stack

Python (data processing, scoring logic, reporting)

MySQL (relational data source)

Power BI (visualization & business insights)

🎯 Project Goal

The goal of this project is to demonstrate how raw operational data can be transformed into decision-ready insights, helping teams:

Identify root causes of friction

Prioritize high-impact improvements

Reduce operational cost and risk
