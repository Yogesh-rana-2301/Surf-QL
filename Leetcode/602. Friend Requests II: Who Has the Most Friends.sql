# Write your MySQL query statement below
WITH cte AS (
    SELECT requester_id AS id, COUNT(*) AS cnt
    FROM RequestAccepted
    GROUP BY requester_id

    UNION ALL 

    SELECT accepter_id AS id, COUNT(*) AS cnt
    FROM RequestAccepted
    GROUP BY accepter_id
) 

SELECT id, SUM(cnt) AS num
FROM cte AS c1 
GROUP BY id
ORDER BY num DESC
LIMIT 1;
