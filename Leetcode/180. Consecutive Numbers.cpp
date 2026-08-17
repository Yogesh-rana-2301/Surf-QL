# Write your MySQL query statement below
WITH cte AS (
    SELECT  num, Lead(num, 1) OVER() AS num1, Lead(num, 2) OVER() AS num2
    FROM Logs
)
SELECT DISTINCT num AS ConsecutiveNums
FROM cte
WHERE (num=num1) AND (num=num2);
