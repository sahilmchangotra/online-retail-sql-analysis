-- ============================================================
-- FILE: 03_revenue_trends.sql
-- DESCRIPTION: Monthly revenue trends, MoM growth and
--              3-month rolling average
-- STAKEHOLDER: Arjun Mehta (Amazon India)
-- DATASET: Online Retail 2009-2011
-- ============================================================

-- ============================================================
-- Q1: Monthly Revenue with Month-over-Month % Change
-- Business Question: What is the monthly revenue trend and
-- which months had the biggest spikes or drops?
-- Stakeholder: Arjun Mehta
-- ============================================================

-- One row in CTE = one month (not per customer!)

WITH monthly_stats AS (
    SELECT
        TO_CHAR(invoice_timestamp, 'YYYY-MM')    AS year_month,
        COUNT(DISTINCT invoice)                   AS total_orders,
        ROUND(SUM(quantity * price_numeric), 2)   AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY TO_CHAR(invoice_timestamp, 'YYYY-MM')
),
mom_calc AS (
    SELECT
        *,
        LAG(total_revenue, 1) OVER (
            ORDER BY year_month
        )                                         AS prev_revenue
    FROM monthly_stats
)
SELECT
    year_month,
    total_orders,
    total_revenue,
    prev_revenue,
    CASE
        WHEN prev_revenue IS NULL THEN NULL
        ELSE ROUND(
            (total_revenue - prev_revenue) * 100.0
            / NULLIF(prev_revenue, 0), 2)
    END                                           AS mom_pct
FROM mom_calc
ORDER BY year_month;

-- LESSON: LAG() must be applied AFTER monthly aggregation
--         Applying LAG at customer-month granularity gives
--         meaningless results — always check one row = one WHAT
-- INSIGHT: Seasonality peaks visible in Q4 months
--          November/December show highest revenue spikes


-- ============================================================
-- Q2: 3-Month Rolling Average Revenue
-- Business Question: Smooth monthly revenue spikes to show
-- underlying trend for forecasting model
-- Stakeholder: Sophie van der Berg
-- ============================================================

-- One row in CTE = one month

WITH monthly_revenue AS (
    SELECT
        TO_CHAR(invoice_timestamp, 'YYYY-MM')   AS year_month,
        ROUND(SUM(quantity * price_numeric), 2)  AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY TO_CHAR(invoice_timestamp, 'YYYY-MM')
),
rolling_calc AS (
    SELECT
        year_month,
        total_revenue,
        ROUND(AVG(total_revenue) OVER (
            ORDER BY year_month
            -- Current month + 2 preceding months = 3 month window
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2)                                    AS rolling_3m_avg
    FROM monthly_revenue
)
SELECT
    year_month,
    total_revenue        AS monthly_revenue,
    rolling_3m_avg
FROM rolling_calc
ORDER BY year_month;

-- NOTE: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--       = current month + 2 months before = 3 month window
-- INSIGHT: Rolling average smooths Q4 spikes and reveals
--          steady underlying growth trend for forecasting


-- ============================================================
-- Q3: Top 5 Countries by Revenue and AOV
-- Business Question: Which markets are high-volume vs
-- high-value per transaction?
-- Stakeholder: Sophie van der Berg
-- ============================================================

-- One row = one country

SELECT
    country,
    COUNT(DISTINCT invoice)                          AS total_orders,
    ROUND(SUM(quantity * price_numeric), 2)          AS total_revenue,
    ROUND(SUM(quantity * price_numeric)
        / COUNT(DISTINCT invoice), 2)                AS average_order_value
FROM online_retail
WHERE customer_id IS NOT NULL
    AND quantity > 0
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 5;

-- FINDING: Netherlands shows high AOV despite fewer orders
--          → likely B2B/wholesale buyers
-- INSIGHT: Netherlands campaign strategy should target
--          wholesale and gifting segments, not mass discounts