
use ecommerce_analysis;
SELECT 
    c.customer_unique_id,
    c.customer_state,
    DATEDIFF(
        '2018-10-17',
        STR_TO_DATE(MAX(o.order_purchase_timestamp), '%d-%m-%Y %H:%i')
    )                                    AS recency,
    COUNT(DISTINCT o.order_id)           AS frequency,
    ROUND(SUM(p.payment_value), 2)       AS monetary,
    ROUND(AVG(p.payment_value), 2)       AS avg_order_value,
    CASE 
        WHEN DATEDIFF(
            '2018-10-17',
            STR_TO_DATE(MAX(o.order_purchase_timestamp), '%d-%m-%Y %H:%i')
        ) > 180 
        THEN 1 ELSE 0 
    END                                  AS is_churned,
    CASE 
        WHEN SUM(p.payment_value) > 1000 
             AND COUNT(DISTINCT o.order_id) > 3 THEN 'Premium'
        WHEN SUM(p.payment_value) > 500  
             AND COUNT(DISTINCT o.order_id) > 1 THEN 'High'
        WHEN SUM(p.payment_value) > 100         THEN 'Medium'
        ELSE                                         'Low'
    END                                  AS customer_segment
FROM customer_data c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id    = p.order_id
GROUP BY c.customer_unique_id, c.customer_state
ORDER BY monetary DESC;

