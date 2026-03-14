-- ============================================================
-- FILE: 05_product_country_analysis.sql
-- DESCRIPTION: Product performance and country revenue analysis
-- STAKEHOLDER: Sophie van der Berg (Amazon Netherlands)
--              Arjun Mehta (Amazon India)
-- DATASET: Online Retail 2009-2011
-- ============================================================


-- ============================================================
-- Q1: Top 10 Products by Revenue and Unique Customers
-- Business Question: Best selling products by total revenue
-- and how many unique customers bought each product
-- Stakeholder: Arjun Mehta
-- ============================================================

-- One row = one product (stockcode + description)

SELECT
    stockcode,
    description,
    COUNT(DISTINCT customer_id)              AS unique_customers,
    ROUND(SUM(quantity * price_numeric), 2)  AS total_revenue
FROM online_retail
WHERE customer_id IS NOT NULL
    AND quantity > 0
GROUP BY stockcode, description
ORDER BY total_revenue DESC
LIMIT 10;

-- NOTE: GROUP BY stockcode + description (not description alone)
--       Two different products can share the same description
--       stockcode is the reliable unique product identifier
-- INSIGHT: Compare unique_customers vs total_revenue to identify
--          whether revenue is driven by broad demand or
--          a few heavy buyers


-- ============================================================
-- Q2: Top 3 Products per Country by Revenue
-- Business Question: Best selling products within each country
-- Stakeholder: Arjun Mehta
-- NOTE: RANK() used — ties allowed
--       Use ROW_NUMBER() for strict top 3 with no ties
-- ============================================================

-- One row in base CTE = one product + country

WITH prod_revenue AS (
    SELECT
        stockcode,
        description,
        country,
        ROUND(SUM(quantity * price_numeric), 2)  AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY stockcode, description, country
),
ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY country
            ORDER BY total_revenue DESC
        )                                        AS rank
    FROM prod_revenue
)
SELECT
    stockcode,
    description,
    country,
    total_revenue,
    rank
FROM ranked
WHERE rank <= 3
ORDER BY country, rank;

-- NOTE: Austria shows 4 rows due to tie at rank 3
--       Two products share identical revenue → both rank 3
--       This is correct RANK() behaviour — honest representation
--       Switch to ROW_NUMBER() if exactly 3 rows needed


-- ============================================================
-- Q3: Customer Retention by Country
-- Business Question: Customers who returned at least once,
-- their active months and revenue vs country average
-- Stakeholder: Arjun Mehta
-- ============================================================

-- One row in base CTE = one customer + country

WITH customer_spend AS (
    SELECT
        customer_id,
        country,
        MIN(TO_CHAR(invoice_timestamp, 'YYYY-MM'))           AS first_month,
        MAX(TO_CHAR(invoice_timestamp, 'YYYY-MM'))           AS last_month,
        COUNT(DISTINCT TO_CHAR(invoice_timestamp, 'YYYY-MM')) AS active_months,
        ROUND(SUM(quantity * price_numeric), 2)               AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
        AND quantity > 0
    GROUP BY customer_id, country
),
customer_purchase AS (
    SELECT
        *,
        AVG(total_revenue) OVER (
            PARTITION BY country
        )                                                     AS country_avg_revenue
    FROM customer_spend
)
SELECT
    customer_id,
    country,
    first_month,
    last_month,
    active_months,
    total_revenue
FROM customer_purchase
WHERE first_month != last_month
    AND total_revenue > country_avg_revenue
ORDER BY country, total_revenue DESC;

-- INSIGHT: Customers with first_month != last_month confirmed
--          as returning buyers
--          Filtering above country average surfaces high value
--          retained customers per market
-- NOTE: country_avg_revenue calculated using window function
--       AVG() OVER (PARTITION BY country)
--       No JOIN or subquery needed — elegant and efficient