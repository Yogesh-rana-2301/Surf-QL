# Write your MySQL query statement below
SELECT s.user_id,
    ROUND(
        AVG(
            CASE 
                WHEN c.action = 'confirmed' THEN 1.00
                ELSE 0
            END
        ),
        2
    ) confirmation_rate
FROM Signups AS s
LEFT JOIN Confirmations AS c 
ON s.user_id = c.user_id
GROUP BY user_id
;
/*




*/
