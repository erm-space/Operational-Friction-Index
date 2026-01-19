/* ============================================================
   FILE: analysis_05_operational_friction_index.sql
   PURPOSE:
   Build the Operational Friction Index (OFI)
   This is the CORE of the project.
   ============================================================ */

USE operational_friction_index;

/* ------------------------------------------------------------
   1. Case-level friction score
   ------------------------------------------------------------ */
SELECT
    c.case_id,
    (
        c.resolution_minutes
        + c.delay_minutes
        + (c.escalated_flag * 20)
        + (c.reopened_flag * 15)
        + (c.has_refund * 25)
        + (ic.friction_weight * 10)
    ) AS case_friction_score
FROM cases c
JOIN issue_catalog ic ON c.issue_id = ic.issue_id;


/* ------------------------------------------------------------
   2. Average OFI by month
   ------------------------------------------------------------ */
SELECT
    cal.year,
    cal.month,
    ROUND(AVG(
        c.resolution_minutes
        + c.delay_minutes
        + (c.escalated_flag * 20)
        + (c.reopened_flag * 15)
        + (c.has_refund * 25)
        + (ic.friction_weight * 10)
    ), 2) AS monthly_ofi
FROM cases c
JOIN calendar cal ON c.date_id = cal.date_id
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
GROUP BY cal.year, cal.month
ORDER BY cal.year, cal.month;


/* ------------------------------------------------------------
   3. OFI by product
   ------------------------------------------------------------ */
SELECT
    p.product_group,
    ROUND(AVG(
        c.resolution_minutes
        + c.delay_minutes
        + (c.escalated_flag * 20)
        + (c.reopened_flag * 15)
        + (c.has_refund * 25)
        + (ic.friction_weight * 10)
    ), 2) AS product_ofi
FROM cases c
JOIN products p ON c.product_id = p.product_id
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
GROUP BY p.product_group
ORDER BY product_ofi DESC;


/* ------------------------------------------------------------
   4. OFI by agent team
   ------------------------------------------------------------ */
SELECT
    a.team,
    ROUND(AVG(
        c.resolution_minutes
        + c.delay_minutes
        + (c.escalated_flag * 20)
        + (c.reopened_flag * 15)
        + (c.has_refund * 25)
        + (ic.friction_weight * 10)
    ), 2) AS team_ofi
FROM cases c
JOIN agents a ON c.agent_id = a.agent_id
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
GROUP BY a.team
ORDER BY team_ofi DESC;


/* ------------------------------------------------------------
   5. Highest friction cases (for Power BI drill-down)
   ------------------------------------------------------------ */
SELECT
    c.case_id,
    c.channel,
    c.priority,
    c.resolution_minutes,
    c.delay_minutes,
    ic.issue_category,
    (
        c.resolution_minutes
        + c.delay_minutes
        + (c.escalated_flag * 20)
        + (c.reopened_flag * 15)
        + (c.has_refund * 25)
        + (ic.friction_weight * 10)
    ) AS case_ofi
FROM cases c
JOIN issue_catalog ic ON c.issue_id = ic.issue_id
ORDER BY case_ofi DESC
LIMIT 100;