# Write your MySQL query statement below
WITH cte AS (
    SELECT p.product_id , p.category ,c.user_id
    FROM ProductPurchases AS c
    JOIN ProductInfo AS p
        ON p.product_id = c.product_id
)

SELECT c1.category AS category1, c2.category AS category2, COUNT(DISTINCT c1.user_id) AS customer_count
FROM cte AS c1
JOIN cte AS c2
    ON c1.category<c2.category
    AND c1.user_id = c2.user_id
GROUP BY c1.category, c2.category
HAVING COUNT(DISTINCT c1.user_id)>=3
ORDER BY customer_count DESC , c1.category ASC, c2.category ASC 
;
