# Write your MySQL query statement below
WITH cte AS (
    SELECT product_id, SUM(unit) AS units
    FROM Orders
    WHERE MONTH(order_date) = 02 AND YEAR(order_date)= 2020
    GROUP BY product_id  
    HAVING  SUM(unit)>=100
)
SELECT p.product_name, c.units AS unit
FROM Products AS p 
JOIN cte AS c
    ON p.product_id = c.product_id
;
