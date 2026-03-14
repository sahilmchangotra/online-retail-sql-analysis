-- ============================================================
-- FILE: 01_customer_segmentation.sql
-- DESCRIPTION: Customer segmentation analysis
-- STAKEHOLDER: Sophie van der Berg (Amazon Netherlands)
--              Arjun Mehta (Amazon India)
-- DATASET: Online Retail 2009-2011
-- ============================================================

-- ============================================================
-- Q1: Repeat vs One-Time Buyers
-- Business Question: What percentage of customers are repeat
-- buyers vs one-time buyers?
-- Stakeholder: Sophie van der Berg
-- ============================================================

WITH customer_spend AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice)               AS total_orders,
        ROUND(SUM(quantity * price_numeric),2) AS total_revenue
    FROM online_retail
    WHERE quantity > 0
        AND customer_id IS NOT NULL
    GROUP BY customer_id
),
customer_segment AS (
    SELECT
        *,
        CASE
            WHEN total_orders > 1 THEN 'Repeat Buyer'
            ELSE 'One-Time'
        END AS customer_type
    FROM customer_spend
)
SELECT
    customer_type,
    COUNT(customer_id)                              AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS customer_pct
FROM customer_segment
GROUP BY customer_type
ORDER BY total_customers DESC;

-- FINDING: ~82% of customers are repeat buyers
-- INSIGHT: Retention strategy should be prioritised over acquisition


-- ============================================================
-- Q2: VIP Customer Identification using HAVING
-- Business Question: Customers with 5+ orders AND AOV > £200
-- Stakeholder: Arjun Mehta
-- ============================================================

SELECT
    customer_id,
    COUNT(DISTINCT invoice)             AS total_orders,
    ROUND(AVG(quantity * price_numeric),2) AS avg_order_value
FROM online_retail
WHERE customer_id IS NOT NULL
    AND quantity > 0
GROUP BY customer_id
HAVING COUNT(DISTINCT invoice) >= 5
    AND AVG(quantity * price_numeric) > 200;

-- NOTE: ROUND() kept in SELECT only, not inside HAVING condition
-- INSIGHT: These customers are VIP candidates for premium loyalty programme


-- ============================================================
-- Q3: RFM Segmentation
-- Business Question: Segment customers by Recency, Frequency,
-- Monetary value using NTILE scoring
-- Stakeholder: Arjun Mehta
-- ============================================================

WITH ref AS (
    SELECT MAX(DATE(invoice_timestamp)) AS ref_date
    FROM online_retail
),
rfm_base AS (
    SELECT
        o.customer_id,
        (r.ref_date - MAX(DATE(o.invoice_timestamp))) AS recency,
        COUNT(DISTINCT o.invoice)                      AS frequency,
        ROUND(SUM(o.quantity * o.price_numeric), 2)    AS monetary
    FROM online_retail o, ref r
    WHERE o.customer_id IS NOT NULL
        AND o.quantity > 0
    GROUP BY o.customer_id, r.ref_date
),
rfm_scored AS (
    SELECT
        *,
        (monetary / frequency)                          AS average_order_value,
        (recency / NULLIF(frequency - 1, 0))            AS avg_days_btw_purchase,
        NTILE(4) OVER (ORDER BY recency DESC)           AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)          AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)           AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4
                 AND m_score >= 4               THEN 'Champions'
            WHEN r_score <= 2 AND m_score >= 4  THEN 'At Risk High Value'
            WHEN f_score >= 4 AND m_score >= 4  THEN 'Loyal'
            WHEN r_score <= 2                   THEN 'Churn Risk'
            ELSE                                     'Needs Attention'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(DISTINCT customer_id)         AS total_customers,
    ROUND(AVG(average_order_value), 2)  AS avg_order_value,
    ROUND(AVG(avg_days_btw_purchase),2) AS avg_days_between_purchases
FROM rfm_segmented
GROUP BY segment
ORDER BY avg_order_value DESC;

-- FINDING: Champions have avg AOV of £705 vs £165 for Churned (4x gap)
-- INSIGHT: At Risk High Value segment = dormant high spenders
--          → priority winback campaign target