# Write your MySQL query statement below
WITH cte AS (
    SELECT visited_on, SUM(amount) AS amount
    FROM Customer
    GROUP BY visited_on
),
cte2 AS (
    SELECT visited_on, ROUND(SUM(amount) OVER(ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS amount, ROUND(AVG(amount) OVER(ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS  average_amount
    FROM cte
)

SELECT visited_on, amount, average_amount
FROM cte2
WHERE DATEDIFF(visited_on, (SELECT MIN(visited_on) FROM Customer)) >= 6
;

/*
 

*/
