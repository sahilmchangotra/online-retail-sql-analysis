-- ============================================================
-- FILE: 02_cohort_analysis.sql
-- DESCRIPTION: Customer cohort retention analysis
-- STAKEHOLDER: Sophie van der Berg (Amazon Netherlands)
-- DATASET: Online Retail 2009-2011
-- ============================================================

-- ============================================================
-- Q1: Cohort Retention Grid
-- Business Question: For each acquisition cohort, how many
-- customers are still purchasing in months 0, 1, 2 and 3?
-- Stakeholder: Sophie van der Berg
-- ============================================================

-- One row in base CTE = one customer (cohort assignment)

WITH customer_purchase AS (
    SELECT
        customer_id,
        TO_CHAR(MIN(invoice_timestamp),'YYYY-MM') AS cohort_month,
        MIN(invoice_timestamp)                     AS first_purchase_date
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY customer_id
),

-- One row = one customer + one transaction (joined to get month_number)

cohort_joined AS (
    SELECT
        o.customer_id,
        c.cohort_month,
        o.invoice_timestamp,
        -- Month number = months elapsed since first purchase
        (EXTRACT(YEAR  FROM o.invoice_timestamp)
            - EXTRACT(YEAR  FROM c.first_purchase_date)) * 12
        + (EXTRACT(MONTH FROM o.invoice_timestamp)
            - EXTRACT(MONTH FROM c.first_purchase_date)) AS month_number
    FROM online_retail o
    JOIN customer_purchase c
        ON o.customer_id = c.customer_id
    WHERE o.quantity > 0
        AND o.customer_id IS NOT NULL
)

-- Pivot: one row = one cohort, columns = month offsets

SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN month_number = 0
          THEN customer_id END)                    AS month_0,
    COUNT(DISTINCT CASE WHEN month_number = 1
          THEN customer_id END)                    AS month_1,
    COUNT(DISTINCT CASE WHEN month_number = 2
          THEN customer_id END)                    AS month_2,
    COUNT(DISTINCT CASE WHEN month_number = 3
          THEN customer_id END)                    AS month_3
FROM cohort_joined
WHERE month_number BETWEEN 0 AND 3
GROUP BY cohort_month
ORDER BY cohort_month;

-- FINDING: Sharp drop from Month 0 to Month 1 across all cohorts
-- INSIGHT: Post-purchase email sequence needed within first 30 days
--          to improve Month 0 → Month 1 retention rate
-- NOTE: month_number arithmetic used instead of date functions
--       for SQL dialect compatibility