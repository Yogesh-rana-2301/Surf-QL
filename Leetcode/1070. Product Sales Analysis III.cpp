# Write your MySQL query statement below
WITH cte AS
(
    SELECT product_id, MIN(Sales.year) AS yr
    FROM Sales
    GROUP BY product_id
)
SELECT s.product_id, s.year AS first_year,s.quantity,s.price
FROM Sales AS s
JOIN cte as c
    ON s.product_id = c.product_id
    AND s.year = c.yr
