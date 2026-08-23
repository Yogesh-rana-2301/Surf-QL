# Write your MySQL query sta(tement below
SELECT t.request_at AS Day, ROUND((SUM(IF(t.status = 'cancelled_by_driver' OR t.status = 'cancelled_by_client' , 1, 0))/COUNT(*)),2) AS `Cancellation Rate`
FROM Trips AS t
JOIN Users AS u
    ON t.client_id = u.users_id
JOIN Users AS u2
    ON t.driver_id = u2.users_id 
WHERE t.request_at BETWEEN "2013-10-01" AND "2013-10-03" AND u.banned = 'NO' AND u2.banned = 'NO'
GROUP BY t.request_at
;
 
