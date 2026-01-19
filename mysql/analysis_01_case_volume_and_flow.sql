/* ============================================================
   FILE: analysis_01_case_volume_and_flow.sql
   PURPOSE:
   Understand how operational load flows over time.
   This establishes the baseline pressure on operations.
   ============================================================ */

USE operational_friction_index;

/* ------------------------------------------------------------
   1. Daily case volume
   Why:
   - Shows workload volatility
   - Used later to normalize friction scores
   ------------------------------------------------------------ */
SELECT
    cal.calendar_date,
    COUNT(c.case_id) AS total_cases
FROM cases c
JOIN calendar cal ON c.date_id = cal.date_id
GROUP BY cal.calendar_date
ORDER BY cal.calendar_date;


/* ------------------------------------------------------------
   2. Monthly case trend
   Why:
   - Identifies seasonal spikes
   - Recruiters LOVE time aggregation
   ------------------------------------------------------------ */
SELECT
    cal.year,
    cal.month,
    cal.month_name,
    COUNT(c.case_id) AS monthly_cases
FROM cases c
JOIN calendar cal ON c.date_id = cal.date_id
GROUP BY cal.year, cal.month, cal.month_name
ORDER BY cal.year, cal.month;


/* ------------------------------------------------------------
   3. Case volume by channel
   Why:
   - Shows where operational pressure originates
   - Important for staffing & automation decisions
   ------------------------------------------------------------ */
SELECT
    c.channel,
    COUNT(*) AS total_cases,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM cases c
GROUP BY c.channel
ORDER BY total_cases DESC;


/* ------------------------------------------------------------
   4. Case status distribution
   Why:
   - Measures resolution effectiveness
   - High "open" or "cancelled" = friction
   ------------------------------------------------------------ */
SELECT
    c.status,
    COUNT(*) AS cases_count
FROM cases c
GROUP BY c.status
ORDER BY cases_count DESC;


/* ------------------------------------------------------------
   5. Priority vs volume
   Why:
   - Shows whether operations are reactive or proactive
   ------------------------------------------------------------ */
SELECT
    c.priority,
    COUNT(*) AS total_cases
FROM cases c
GROUP BY c.priority
ORDER BY total_cases DESC