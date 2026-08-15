WITH cnt AS (
    SELECT COUNT(*) AS cnt1
    FROM Users
)
SELECT 
    r.contest_id,
    ROUND((COUNT(*) / cnt1 * 100),2) AS percentage
FROM Register AS r
CROSS JOIN cnt
GROUP BY r.contest_id
ORDER BY percentage DESC, r.contest_id ASC;
