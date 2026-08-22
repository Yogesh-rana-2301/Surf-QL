# Write your MySQL query statement below


SELECT c.user_id, ROUND(AVG(c.activity_duration),2) AS trial_avg_duration, ROUND(AVG(p.activity_duration),2) AS paid_avg_duration
FROM UserActivity AS c
JOIN UserActivity AS p
    ON c.user_id= p.user_id
    AND c.activity_type = 'free_trial'
    AND p.activity_type= 'paid'
GROUP BY c.user_id
ORDER BY c.user_id ASC;
