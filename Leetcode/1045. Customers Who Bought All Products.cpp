# Write your MySQL query statement below
WITH c AS (
    SELECT COUNT(DISTINCT product_key) AS n
    FROM Product
)
SELECT customer_id
FROM Customer
CROSS JOIN c 
GROUP BY Customer.customer_id
HAVING COUNT(DISTINCT product_key) = MAX(c.n)
;



SELECT customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (
    SELECT COUNT(DISTINCT product_key)
    FROM Product
);
