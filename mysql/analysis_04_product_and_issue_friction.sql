/* ============================================================
   FILE: analysis_04_product_and_issue_friction.sql
   PURPOSE:
   Detect systemic friction caused by products and issues.
   ============================================================ */

USE operational_friction_index;

/* ------------------------------------------------------------
   1. Case volume by product
   ------------------------------------------------------------ */
SELECT
    p.product_group,
    COUNT(*) AS total_cases
FROM cases c
JOIN products p ON c.product_id = p.product_id
GROUP BY p.product_group
ORDER BY total_cases DESC;


/* ------------------------------------------------------------
   2. Average resolution by product risk
   ------------------------------------------------------------ */
SELECT
    p.product_group,
    ROUND(AVG(c.resolution_minutes), 2) AS avg_resolution
FROM cases c
JOIN products p ON c.product_id = p.product_id
GROUP BY p.product_group
ORDER BY avg_resolution DESC;


/* ------------------------------------------------------------
   3. Issue category friction
   ------------------------------------------------------------ */
SELECT
    ic.issue_category,
    COUNT(*) AS cases_count,
    ROUND(AVG(c.resolution_minutes), 2) AS avg_resolution
FROM cases c
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
GROUP BY ic.issue_category
ORDER BY avg_resolution DESC;


/* ------------------------------------------------------------
   4. Root cause analysis
   ------------------------------------------------------------ */
SELECT
    ic.root_cause,
    COUNT(*) AS cases_count
FROM cases c
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
GROUP BY ic.root_cause
ORDER BY cases_count DESC;


/* ------------------------------------------------------------
   5. Severity-weighted friction
   ------------------------------------------------------------ */
SELECT
    ic.severity,
    ROUND(
        AVG(c.resolution_minutes) * AVG(ic.severity_multiplier),
    2) AS severity_friction_score
FROM cases c
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
GROUP BY ic.severity
ORDER BY severity_friction_score DESC;