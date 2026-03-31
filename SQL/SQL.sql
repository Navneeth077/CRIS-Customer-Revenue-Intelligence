-- ============================================================
-- PROJECT   : Customer Revenue Intelligence System
-- AUTHOR    : Navaneeth Chandra
-- DATE      : 2026-03-12
-- TOOL      : MySQL Workbench
-- DATASET   : Olist Brazilian E-Commerce
-- PURPOSE   : RFM Analysis, Churn Labeling, Revenue Segmentation
-- ============================================================

-- ------------------------------------------------------------
-- SETUP
-- ------------------------------------------------------------


CREATE DATABASE IF NOT EXISTS customer_revenue_intelligence;
USE customer_revenue_intelligence;


-- ============================================================
-- QUERY 1 : Total Revenue Per Customer
-- PURPOSE : Identify highest revenue generating customers
-- ============================================================

SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id)        AS total_orders,
    ROUND(SUM(p.payment_value), 2)    AS total_revenue,
    ROUND(AVG(p.payment_value), 2)    AS avg_order_value
FROM customer_data c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id    = p.order_id
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 2 : RFM Scoring (Recency, Frequency, Monetary)
-- PURPOSE : Core metric for customer behavior analysis
-- NOTE    : Reference date = 2018-10-17 (last date in dataset)
-- ============================================================

SELECT 
    c.customer_unique_id,
    DATEDIFF(
        '2018-10-17', 
        STR_TO_DATE(MAX(o.order_purchase_timestamp), '%d-%m-%Y %H:%i')
    )                                  AS recency,
    COUNT(DISTINCT o.order_id)         AS frequency,
    ROUND(SUM(p.payment_value), 2)     AS monetary
FROM customer_data c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id    = p.order_id
GROUP BY c.customer_unique_id
ORDER BY monetary DESC
LIMIT 10;


-- ============================================================
-- QUERY 3 : Churn Labeling
-- PURPOSE : Identify customers who have not purchased in 180+ days
-- LOGIC   : is_churned = 1 (churned) | 0 (active)
-- ============================================================

SELECT 
    c.customer_unique_id,
    MAX(o.order_purchase_timestamp)   AS last_purchase_date,
    DATEDIFF(
        '2018-10-17',
        STR_TO_DATE(MAX(o.order_purchase_timestamp), '%d-%m-%Y %H:%i')
    )                                  AS days_since_purchase,
    CASE 
        WHEN DATEDIFF(
            '2018-10-17',
            STR_TO_DATE(MAX(o.order_purchase_timestamp), '%d-%m-%Y %H:%i')
        ) > 180 
        THEN 1 
        ELSE 0 
    END                                AS is_churned
FROM customer_data c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY days_since_purchase ASC
LIMIT 10;


-- ============================================================
-- QUERY 4 : Revenue by State
-- PURPOSE : Identify geographic concentration of revenue
-- ============================================================

SELECT 
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)  AS total_customers,
    ROUND(SUM(p.payment_value), 2)        AS total_revenue,
    ROUND(AVG(p.payment_value), 2)        AS avg_revenue_per_customer
FROM customer_data c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id    = p.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 5 : Top Product Categories by Revenue
-- PURPOSE : Understand which product categories drive revenue
-- ============================================================

SELECT 
    pr.product_category_name,
    COUNT(DISTINCT o.order_id)         AS total_orders,
    ROUND(SUM(p.payment_value), 2)     AS total_revenue
FROM order_items oi
JOIN orders o         ON oi.order_id   = o.order_id
JOIN order_payments p ON o.order_id    = p.order_id
JOIN products pr      ON oi.product_id = pr.product_id
GROUP BY pr.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 6 : Customer Segmentation (RFM Based)
-- PURPOSE : Classify customers into Premium, High, Medium, Low
-- LOGIC   :
--   Premium → monetary > 1000 AND frequency > 3
--   High    → monetary > 500  AND frequency > 1
--   Medium  → monetary > 100
--   Low     → everything else
-- ============================================================

SELECT 
    customer_unique_id,
    recency,
    frequency,
    monetary,
    CASE 
        WHEN monetary > 1000 AND frequency > 3 THEN 'Premium'
        WHEN monetary > 500  AND frequency > 1 THEN 'High'
        WHEN monetary > 100                    THEN 'Medium'
        ELSE                                        'Low'
    END AS customer_segment
FROM (
    SELECT 
        c.customer_unique_id,
        DATEDIFF(
            '2018-10-17',
            STR_TO_DATE(MAX(o.order_purchase_timestamp), '%d-%m-%Y %H:%i')
        )                                AS recency,
        COUNT(DISTINCT o.order_id)       AS frequency,
        ROUND(SUM(p.payment_value), 2)   AS monetary
    FROM customer_data c
    JOIN orders o         ON c.customer_id = o.customer_id
    JOIN order_payments p ON o.order_id    = p.order_id
    GROUP BY c.customer_unique_id
) rfm
ORDER BY monetary DESC
LIMIT 10;
