WITH first_orders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM Delivery
    GROUP BY customer_id
)
SELECT 
    ROUND(
        100 * SUM(
            CASE
                WHEN d.order_date = d.customer_pref_delivery_date THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS immediate_percentage
FROM Delivery AS d
JOIN first_orders AS f
    ON d.customer_id = f.customer_id
    AND d.order_date = f.first_order_date;
