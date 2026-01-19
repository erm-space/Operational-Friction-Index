/* ============================================================
   Operational Friction Index — Full MySQL Build + Clean Upload
   - Works in MySQL Workbench
   - Uses literal file paths (NO CONCAT)
   - Handles comma decimals for risk_score / refund_amount / weights
   - Loads in correct order to avoid FK issues

   IMPORTANT:
   1) Put ALL CSV files here:  C:/mysql_import/
   2) Files expected:
      calendar.csv, customers.csv, agents.csv, products.csv,
      issue_catalog.csv, cases.csv, case_timeline.csv, refunds.csv
   ============================================================ */


/* ---------- 0) Database reset ---------- */
DROP DATABASE IF EXISTS operational_friction_index;
CREATE DATABASE operational_friction_index;
USE operational_friction_index;


/* ---------- 1) Allow LOCAL INFILE (you may need admin rights) ---------- */
-- If this errors, ignore it and enable LOCAL INFILE in Workbench settings/server config.
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';


/* ---------- 2) Tables (no DIM naming) ---------- */

CREATE TABLE calendar (
  date_id INT PRIMARY KEY,
  calendar_date DATE NOT NULL,
  year INT NOT NULL,
  month INT NOT NULL,
  month_name VARCHAR(10) NOT NULL,
  quarter INT NOT NULL,
  day_name VARCHAR(15) NOT NULL,
  week_of_year INT NOT NULL,
  INDEX idx_calendar_calendar_date (calendar_date)
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  country VARCHAR(30) NOT NULL,
  region VARCHAR(20) NOT NULL,
  segment VARCHAR(20) NOT NULL,
  signup_year INT NOT NULL,
  segment_multiplier DECIMAL(4,2) NOT NULL,
  INDEX idx_customers_country (country),
  INDEX idx_customers_segment (segment)
) ENGINE=InnoDB;

CREATE TABLE agents (
  agent_id INT PRIMARY KEY,
  team VARCHAR(30) NOT NULL,
  shift VARCHAR(15) NOT NULL,
  tenure_months INT NOT NULL,
  speed_factor DECIMAL(4,2) NOT NULL,
  INDEX idx_agents_team (team),
  INDEX idx_agents_shift (shift)
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id INT PRIMARY KEY,
  product_group VARCHAR(30) NOT NULL,
  base_price_eur DECIMAL(10,2) NOT NULL,
  risk_score DECIMAL(8,6) NOT NULL,
  INDEX idx_products_group (product_group)
) ENGINE=InnoDB;

CREATE TABLE issue_catalog (
  issue_id INT PRIMARY KEY,
  issue_category VARCHAR(30) NOT NULL,
  root_cause VARCHAR(60) NOT NULL,
  severity VARCHAR(10) NOT NULL,
  friction_weight DECIMAL(4,2) NOT NULL,
  severity_multiplier DECIMAL(4,2) NOT NULL,
  INDEX idx_issue_category (issue_category),
  INDEX idx_issue_severity (severity)
) ENGINE=InnoDB;

CREATE TABLE cases (
  case_id INT PRIMARY KEY,
  date_id INT NOT NULL,
  customer_id INT NOT NULL,
  agent_id INT NOT NULL,
  product_id INT NOT NULL,
  issue_id INT NOT NULL,
  channel VARCHAR(15) NOT NULL,
  status VARCHAR(15) NOT NULL,
  priority VARCHAR(10) NOT NULL,
  escalated_flag TINYINT NOT NULL,
  reopened_flag TINYINT NOT NULL,
  is_delayed TINYINT NOT NULL,
  delay_minutes INT NOT NULL,
  is_cancelled TINYINT NOT NULL,
  resolution_minutes INT NOT NULL,
  has_refund TINYINT NOT NULL,

  INDEX idx_cases_date (date_id),
  INDEX idx_cases_customer (customer_id),
  INDEX idx_cases_agent (agent_id),
  INDEX idx_cases_product (product_id),
  INDEX idx_cases_issue (issue_id),
  INDEX idx_cases_channel (channel),
  INDEX idx_cases_status (status),
  INDEX idx_cases_priority (priority),

  CONSTRAINT fk_cases_calendar  FOREIGN KEY (date_id)     REFERENCES calendar(date_id),
  CONSTRAINT fk_cases_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_cases_agents    FOREIGN KEY (agent_id)    REFERENCES agents(agent_id),
  CONSTRAINT fk_cases_products  FOREIGN KEY (product_id)  REFERENCES products(product_id),
  CONSTRAINT fk_cases_issue     FOREIGN KEY (issue_id)    REFERENCES issue_catalog(issue_id)
) ENGINE=InnoDB;

CREATE TABLE case_timeline (
  event_id INT PRIMARY KEY,
  case_id INT NOT NULL,
  event_type VARCHAR(30) NOT NULL,
  event_timestamp DATETIME NOT NULL,

  INDEX idx_timeline_case (case_id),
  INDEX idx_timeline_type (event_type),
  INDEX idx_timeline_time (event_timestamp),

  CONSTRAINT fk_timeline_cases FOREIGN KEY (case_id) REFERENCES cases(case_id)
) ENGINE=InnoDB;

CREATE TABLE refunds (
  refund_id INT PRIMARY KEY,
  case_id INT NOT NULL,
  refund_type VARCHAR(15) NOT NULL,
  refund_amount_eur DECIMAL(12,2) NOT NULL,

  INDEX idx_refunds_case (case_id),
  INDEX idx_refunds_type (refund_type),

  CONSTRAINT fk_refunds_cases FOREIGN KEY (case_id) REFERENCES cases(case_id)
) ENGINE=InnoDB;


/* ---------- 3) Clean reload (child tables first) ---------- */
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE refunds;
TRUNCATE TABLE case_timeline;
TRUNCATE TABLE cases;

TRUNCATE TABLE issue_catalog;
TRUNCATE TABLE products;
TRUNCATE TABLE agents;
TRUNCATE TABLE customers;
TRUNCATE TABLE calendar;

SET FOREIGN_KEY_CHECKS = 1;


/* ============================================================
   4) DATA LOADS (all from C:/mysql_import/)
   ============================================================ */


/* ---- 4.1 calendar.csv ----
   CSV columns expected:
   date_id, calendar_date, year, month, month_name, quarter, day_name, week_of_year
*/
LOAD DATA LOCAL INFILE 'C:/mysql_import/calendar.csv'
INTO TABLE calendar
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(date_id, @d, year, month, month_name, quarter, day_name, week_of_year)
SET calendar_date = STR_TO_DATE(@d, '%Y-%m-%d');


/* ---- 4.2 customers.csv ---- */
LOAD DATA LOCAL INFILE 'C:/mysql_import/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(customer_id, country, region, segment, signup_year, segment_multiplier);


/* ---- 4.3 agents.csv ---- */
LOAD DATA LOCAL INFILE 'C:/mysql_import/agents.csv'
INTO TABLE agents
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(agent_id, team, shift, tenure_months, speed_factor);


/* ---- 4.4 products.csv ----
   risk_score sometimes comes with comma decimals → parse safely
*/
LOAD DATA LOCAL INFILE 'C:/mysql_import/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, product_group, base_price_eur, @risk_raw)
SET risk_score = CAST(REPLACE(@risk_raw, ',', '.') AS DECIMAL(8,6));


/* ---- 4.5 issue_catalog.csv ----
   Your final table columns:
   issue_id, issue_category, root_cause, severity, friction_weight, severity_multiplier
   (Weights may have comma decimals → parse safely)
*/
LOAD DATA LOCAL INFILE 'C:/mysql_import/issue_catalog.csv'
INTO TABLE issue_catalog
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(issue_id, issue_category, root_cause, severity, @fw_raw, @sm_raw)
SET
  friction_weight     = CAST(REPLACE(@fw_raw, ',', '.') AS DECIMAL(4,2)),
  severity_multiplier = CAST(REPLACE(@sm_raw, ',', '.') AS DECIMAL(4,2));


/* ---- 4.6 cases.csv ---- */
LOAD DATA LOCAL INFILE 'C:/mysql_import/cases.csv'
INTO TABLE cases
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(case_id, date_id, customer_id, agent_id, product_id, issue_id, channel, status, priority,
 escalated_flag, reopened_flag, is_delayed, delay_minutes, is_cancelled, resolution_minutes, has_refund);


/* ---- 4.7 case_timeline.csv ----
   Your table has ONLY 4 columns:
   event_id, case_id, event_type, event_timestamp

   Your CSV had extra columns before (actor_type etc).
   So we load only what we need and SKIP everything else safely.

   Assumption about CSV order (based on what you showed earlier):
   event_id, case_id, event_timestamp, event_type, ...extras...
*/
LOAD DATA LOCAL INFILE 'C:/mysql_import/case_timeline.csv'
INTO TABLE case_timeline
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@event_id, @case_id, @ts, @event_type,
 @skip1, @skip2, @skip3, @skip4, @skip5, @skip6, @skip7, @skip8)
SET
  event_id        = @event_id,
  case_id         = @case_id,
  event_type      = @event_type,
  event_timestamp = STR_TO_DATE(@ts, '%Y-%m-%d %H:%i:%s');


/* ---- 4.8 refunds.csv ----
   refund_amount_eur might have comma decimals → parse safely
*/
LOAD DATA LOCAL INFILE 'C:/mysql_import/refunds.csv'
INTO TABLE refunds
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(refund_id, case_id, refund_type, @amt_raw)
SET refund_amount_eur = CAST(REPLACE(@amt_raw, ',', '.') AS DECIMAL(12,2));


/* ---------- 5) Sanity checks (what recruiters LOVE) ---------- */

-- Row counts (REAL counts)
SELECT 'agents'        AS tbl, COUNT(*) AS cnt FROM agents
UNION ALL SELECT 'customers',     COUNT(*) FROM customers
UNION ALL SELECT 'products',      COUNT(*) FROM products
UNION ALL SELECT 'issue_catalog', COUNT(*) FROM issue_catalog
UNION ALL SELECT 'calendar',      COUNT(*) FROM calendar
UNION ALL SELECT 'refunds',       COUNT(*) FROM refunds
UNION ALL SELECT 'case_timeline', COUNT(*) FROM case_timeline
UNION ALL SELECT 'cases',         COUNT(*) FROM cases;

-- Any missing foreign keys in the fact table?
SELECT
  SUM(c.customer_id IS NULL) AS missing_customer,
  SUM(c.agent_id    IS NULL) AS missing_agent,
  SUM(c.product_id  IS NULL) AS missing_product,
  SUM(c.issue_id    IS NULL) AS missing_issue,
  SUM(c.date_id     IS NULL) AS missing_date
FROM cases c;

-- Quick preview
SELECT * FROM issue_catalog LIMIT 10;
SELECT * FROM cases LIMIT 5;
SELECT * FROM refunds LIMIT 5;
SELECT * FROM case_timeline LIMIT 5;