# Write your MySQL query statement below
SELECT m.employee_id, m.name, COUNT(*) AS reports_count, ROUND(AVG(e.age),0) AS average_age
FROM Employees AS e
JOIN Employees AS m
    ON m.employee_id = e.reports_to
GROUP BY m.employee_id
ORDER BY m.employee_id;
