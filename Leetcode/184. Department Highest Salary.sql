# Write your MySQL query statement below
WITH cte AS (
    SELECT id , name  , salary , departmentId , RANK() OVER (PARTITION BY departmentId ORDER BY salary DESC)AS rnk
    FROM Employee
)
SELECT d.name AS Department , e.name AS Employee , e.salary AS Salary 
FROM cte e
JOIN Department d
    ON e.departmentId = d.id 
WHERE rnk =1;
 
