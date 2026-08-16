# Write your MySQL query statement below

SELECT a.activity_date AS day,  COUNT(DISTINCT a.user_id) AS active_users
FROM Activity AS a
WHERE a.activity_date BETWEEN DATE_SUB('2019-07-28', INTERVAL 30 DAY) AND '2019-07-27'
GROUP BY a.activity_date;

/*
 

*/
