# Write your MySQL query statement below
WITH cte AS (
    SELECT player_id, MIN(event_date) AS daet
    FROM Activity
    GROUP BY player_id
)
SELECT ROUND(COUNT(*)/(SELECT COUNT(*) FROM cte),2) AS fraction
FROM Activity AS a
JOIN cte as b
    ON a.player_id = b.player_id
    AND TIMESTAMPDIFF(DAY, b.daet, a.event_date) = 1
;
