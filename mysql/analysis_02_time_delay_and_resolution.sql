/* ============================================================
   FILE: analysis_02_time_delay_and_resolution.sql
   PURPOSE:
   Measure time-based friction: delays and resolution speed.
   Time = cost.
   ============================================================ */

USE operational_friction_index;

/* ------------------------------------------------------------
   1. Average resolution time
   Why:
   - Core operational efficiency KPI
   ------------------------------------------------------------ */
SELECT
    ROUND(AVG(resolution_minutes), 2) AS avg_resolution_minutes,
    ROUND(MAX(resolution_minutes), 2) AS max_resolution_minutes,
    ROUND(MIN(resolution_minutes), 2) AS min_resolution_minutes
FROM cases;


/* ------------------------------------------------------------
   2. Resolution time by priority
   Why:
   - High priority should resolve faster
   - If not → process failure
   ------------------------------------------------------------ */
SELECT
    priority,
    ROUND(AVG(resolution_minutes), 2) AS avg_resolution_minutes
FROM cases
GROUP BY priority
ORDER BY avg_resolution_minutes DESC;


/* ------------------------------------------------------------
   3. Delay impact analysis
   Why:
   - Delays are direct friction contributors
   ------------------------------------------------------------ */
SELECT
    is_delayed,
    COUNT(*) AS case_count,
    ROUND(AVG(delay_minutes), 2) AS avg_delay_minutes
FROM cases
GROUP BY is_delayed;


/* ------------------------------------------------------------
   4. Delay by issue severity
   Why:
   - High severity delays are critical risks
   ------------------------------------------------------------ */
SELECT
    ic.severity,
    COUNT(*) AS delayed_cases,
    ROUND(AVG(c.delay_minutes), 2) AS avg_delay
FROM cases c
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
WHERE c.is_delayed = 1
GROUP BY ic.severity
ORDER BY avg_delay DESC;


/* ------------------------------------------------------------
   5. Cancelled vs delayed relationship
   Why:
   - Tests whether delays cause cancellations
   ------------------------------------------------------------ */
SELECT
    is_delayed,
    is_cancelled,
    COUNT(*) AS case_count
FROM cases
GROUP BY is_delayed, is_cancelled
ORDER BY is_delayed DESC, is_cancelled DESC;
