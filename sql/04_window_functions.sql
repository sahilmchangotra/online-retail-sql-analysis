-- ============================================================
-- FILE: 04_window_functions.sql
-- DESCRIPTION: Window function practice — RANK, DENSE_RANK,
--              ROW_NUMBER, NTILE, LAG, LEAD, FILTER(WHERE)
-- STAKEHOLDER: Sophie van der Berg (Amazon Netherlands)
--              Arjun Mehta (Amazon India)
-- DATASET: Online Retail 2009-2011
-- ============================================================


-- ============================================================
-- Q1: RANK + PARTITION BY Multiple Columns
-- Business Question: Top 3 best selling products by revenue
-- within each country AND each month
-- Stakeholder: Arjun Mehta
-- NOTE: RANK() used — ties allowed (two products with same
--       revenue both appear in top 3)
-- ============================================================

-- One row in base CTE = one customer + country + month

WITH customer_spend AS (
    SELECT
        customer_id,
        TO_CHAR(invoice_timestamp, 'YYYY-MM')    AS year_month,
        country,
        ROUND(SUM(quantity * price_numeric), 2)  AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY customer_id,
             country,
             TO_CHAR(invoice_timestamp, 'YYYY-MM')
),
ranked AS (
    SELECT
        customer_id,
        year_month,
        country,
        total_revenue,
        RANK() OVER (
            PARTITION BY country, year_month
            ORDER BY total_revenue DESC
        )                                        AS revenue_rank
    FROM customer_spend
)
SELECT
    country,
    year_month,
    customer_id,
    total_revenue,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 3
ORDER BY country, year_month, revenue_rank;

-- NOTE: RANK() vs ROW_NUMBER() decision:
--       RANK()       → ties allowed, rank gaps appear (1,1,3)
--       ROW_NUMBER() → no ties, always exactly N rows per partition
--       DENSE_RANK() → ties allowed, no gaps (1,1,2)
-- INSIGHT: Two customers with identical spend in same
--          country-month both appear — honest representation


-- ============================================================
-- Q2: ROW_NUMBER — Product Deduplication
-- Business Question: Clean product master table — one row per
-- StockCode keeping only most recently used description
-- Stakeholder: Sophie van der Berg
-- NOTE: ROW_NUMBER() chosen because timestamps are granular
--       — no ties possible, always exactly 1 row per product
-- ============================================================

-- One row in CTE = one product + transaction (before dedup)

WITH ranked AS (
    SELECT
        stockcode,
        description,
        invoice_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY stockcode
            ORDER BY invoice_timestamp DESC
        )                                        AS row_num
    FROM online_retail
)
SELECT
    stockcode,
    description,
    DATE(invoice_timestamp)                      AS last_seen_date
FROM ranked
WHERE row_num = 1;

-- USE CASE: ROW_NUMBER deduplication pattern
--           "Keep only the latest/first record per group"
--           Most common real-world window function application


-- ============================================================
-- Q3: LAG + PARTITION BY Multiple Columns
-- Business Question: Month-over-month revenue change per
-- customer per country with trend flag
-- Stakeholder: Arjun Mehta
-- ============================================================

-- One row in base CTE = one customer + country + month

WITH customer_spend AS (
    SELECT
        customer_id,
        country,
        TO_CHAR(invoice_timestamp, 'YYYY-MM')    AS year_month,
        ROUND(SUM(quantity * price_numeric), 2)  AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY customer_id,
             country,
             TO_CHAR(invoice_timestamp, 'YYYY-MM')
),
month_change AS (
    SELECT
        *,
        LAG(total_revenue, 1) OVER (
            -- Resets per customer-country combination
            -- No bleed across markets
            PARTITION BY customer_id, country
            ORDER BY year_month
        )                                        AS prev_month_revenue
    FROM customer_spend
)
SELECT
    customer_id,
    country,
    year_month,
    prev_month_revenue,
    total_revenue,
    CASE
        WHEN prev_month_revenue IS NULL          THEN 'New'
        WHEN total_revenue > prev_month_revenue  THEN 'Increased'
        WHEN total_revenue < prev_month_revenue  THEN 'Decreased'
        WHEN total_revenue = prev_month_revenue  THEN 'Flat'
    END                                          AS mom_revenue_change
FROM month_change;

-- INSIGHT: PARTITION BY customer_id, country ensures a customer
--          active in both Germany and Netherlands gets independent
--          LAG calculations per country — no cross-market bleed


-- ============================================================
-- Q4: FILTER(WHERE) — Conditional Aggregations
-- Business Question: Total revenue, bulk order revenue
-- (quantity > 10) and premium revenue (price > £5)
-- side by side per country — no JOINs needed
-- Stakeholder: Sophie van der Berg
-- ============================================================

-- One row = one country

SELECT
    country,
    ROUND(SUM(quantity * price_numeric), 2)
                                                 AS total_revenue,
    ROUND(SUM(quantity * price_numeric)
        FILTER(WHERE quantity > 10), 2)          AS bulk_revenue,
    ROUND(SUM(quantity * price_numeric)
        FILTER(WHERE price_numeric > 5), 2)      AS premium_revenue
FROM online_retail
WHERE customer_id IS NOT NULL
    AND quantity > 0
GROUP BY country
ORDER BY total_revenue DESC;

-- NOTE: FILTER(WHERE) applies condition to specific aggregation only
--       Alternative to multiple subqueries or JOINs
--       bulk_revenue and premium_revenue always <= total_revenue
--       Use as sanity check when validating results


-- ============================================================
-- Q5: DENSE_RANK + FILTER + HAVING
-- Business Question: Countries where top bulk product
-- contributes more than 20% of country total revenue
-- Stakeholder: Sophie van der Berg
-- ============================================================

-- One row = one product + country

-- ANALYTICAL DECISION: Threshold set at 20% not 40%
-- REASON: Diagnostic analysis showed bulk_revenue was NULL
--         for all products initially due to NULLS LAST issue.
--         After fix, no country exceeded 40% concentration.
--         20% threshold chosen based on actual data distribution
--         to surface meaningful concentration risk markets.

-- DIAGNOSTIC QUERIES RUN:
-- 1. Checked rows_with_qty_over_10 = 250,474 out of 805,620
-- 2. Found DENSE_RANK ordered NULLs first by default
-- 3. Added NULLS LAST + pre-filter WHERE bulk_revenue > 0

WITH product_country AS (
    SELECT
        stockcode,
        description,
        country,
        ROUND(SUM(quantity * price_numeric), 2)
                                                 AS total_revenue,
        ROUND(SUM(quantity * price_numeric)
            FILTER(WHERE quantity > 10), 2)      AS bulk_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY stockcode, description, country
),
ranked AS (
    SELECT
        *,
        SUM(total_revenue) OVER (
            PARTITION BY country
        )                                        AS country_total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY country
            ORDER BY bulk_revenue DESC NULLS LAST
            -- DENSE_RANK chosen over RANK:
            -- Tied bulk revenues get same rank with no gaps
            -- Saudi Arabia case: 3 products tied at rank 1
        )                                        AS rnk
    FROM product_country
    WHERE bulk_revenue IS NOT NULL
        AND bulk_revenue > 0
)
SELECT
    stockcode,
    description,
    country,
    bulk_revenue,
    country_total_revenue,
    ROUND(bulk_revenue * 100.0
        / NULLIF(country_total_revenue, 0), 1)   AS bulk_pct_of_country
FROM ranked
WHERE rnk = 1
GROUP BY stockcode, description, country,
         bulk_revenue, country_total_revenue, rnk
HAVING bulk_revenue > 0.20 * country_total_revenue
ORDER BY bulk_pct_of_country DESC;

-- FINDING: Nigeria (38.6%), West Indies (29%), Saudi Arabia (24.2%)
--          Brazil (23.2%) show highest bulk concentration
-- INSIGHT: Brazil most actionable — REGENCY CAKESTAND drives
--          23% of bulk revenue → supply chain risk
-- NOTE: Saudi Arabia shows 3-way tie → DENSE_RANK correctly
--       surfaces all 3 products unlike RANK()


-- ============================================================
-- Q6: NTILE + HAVING — Revenue Quartile Segmentation
-- Business Question: Bucket customers into 4 revenue quartiles
-- Show only quartiles where avg AOV exceeds £150
-- Stakeholder: Arjun Mehta
-- ============================================================

-- One row in base CTE = one customer

WITH customer_spend AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice)                  AS total_orders,
        ROUND(SUM(quantity * price_numeric), 2)  AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY customer_id
),
quartiled AS (
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY total_revenue ASC
        )                                        AS quartile
    FROM customer_spend
),
quartile_labelled AS (
    SELECT
        customer_id,
        total_orders,
        total_revenue,
        quartile,
        CASE
            WHEN quartile = 4  THEN 'Champion'
            WHEN quartile = 3  THEN 'Loyal'
            WHEN quartile = 2  THEN 'At Risk'
            WHEN quartile = 1  THEN 'Churned'
        END                                      AS segment
    FROM quartiled
)
SELECT
    segment,
    COUNT(customer_id)                           AS total_customers,
    ROUND(AVG(total_revenue / total_orders), 2)  AS avg_order_value
FROM quartile_labelled
GROUP BY segment
HAVING AVG(total_revenue / total_orders) > 150
ORDER BY avg_order_value DESC;

-- FINDING: Champion £705, Loyal £397, At Risk £297, Churned £165
--          All segments exceed £150 threshold
-- INSIGHT: Even Churned customers have £165 AOV
--          → dormant high-potential, not low-value
--          → winback campaigns justified for all segments