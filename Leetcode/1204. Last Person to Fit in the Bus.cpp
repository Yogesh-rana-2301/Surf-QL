# Write your MySQL query statement below
WITH cte AS (
    SELECT person_id, person_name, SUM(weight) OVER (ORDER BY turn
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS wt
    FROM Queue
    ORDER BY wt DESC
)
SELECT person_name
FROM cte
WHERE wt <=1000
LIMIT 1
;

