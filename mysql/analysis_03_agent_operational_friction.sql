/* ============================================================
   FILE: analysis_03_agent_operational_friction.sql
   PURPOSE:
   Identify human-driven operational friction.
   ============================================================ */

USE operational_friction_index;

/* ------------------------------------------------------------
   1. Agent workload
   Why:
   - Overloaded agents cause systemic friction
   ------------------------------------------------------------ */
SELECT
    a.agent_id,
    a.team,
    COUNT(c.case_id) AS handled_cases
FROM agents a
JOIN cases c ON a.agent_id = c.agent_id
GROUP BY a.agent_id, a.team
ORDER BY handled_cases DESC;


/* ------------------------------------------------------------
   2. Agent resolution efficiency
   Why:
   - Compare speed vs volume
   ------------------------------------------------------------ */
SELECT
    a.agent_id,
    a.team,
    ROUND(AVG(c.resolution_minutes), 2) AS avg_resolution
FROM agents a
JOIN cases c ON a.agent_id = c.agent_id
GROUP BY a.agent_id, a.team
ORDER BY avg_resolution DESC;


/* ------------------------------------------------------------
   3. Escalation rate by agent
   Why:
   - Escalations = failure points
   ------------------------------------------------------------ */
SELECT
    a.agent_id,
    COUNT(*) AS total_cases,
    SUM(c.escalated_flag) AS escalations,
    ROUND(SUM(c.escalated_flag) / COUNT(*) * 100, 2) AS escalation_rate_pct
FROM agents a
JOIN cases c ON a.agent_id = c.agent_id
GROUP BY a.agent_id
ORDER BY escalation_rate_pct DESC;


/* ------------------------------------------------------------
   4. Reopen rate by agent
   Why:
   - Reopened cases signal poor resolution quality
   ------------------------------------------------------------ */
SELECT
    a.agent_id,
    COUNT(*) AS total_cases,
    SUM(c.reopened_flag) AS reopened_cases,
    ROUND(SUM(c.reopened_flag) / COUNT(*) * 100, 2) AS reopen_rate_pct
FROM agents a
JOIN cases c ON a.agent_id = c.agent_id
GROUP BY a.agent_id
ORDER BY reopen_rate_pct DESC;


/* ------------------------------------------------------------
   5. Agent friction score (simple)
   Why:
   - Early OFI component
   ------------------------------------------------------------ */
SELECT
    a.agent_id,
    ROUND(
        AVG(c.resolution_minutes)
        + SUM(c.escalated_flag) * 10
        + SUM(c.reopened_flag) * 5
    , 2) AS agent_friction_score
FROM agents a
JOIN cases c ON a.agent_id = c.agent_id
GROUP BY a.agent_id
ORDER BY agent_friction_score DESC;