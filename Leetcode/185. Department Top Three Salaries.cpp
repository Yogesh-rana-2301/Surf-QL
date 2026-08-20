# Write your MySQL query statement below
WITH cte AS (
    SELECT id , name  , salary , departmentId , DENSE_RANK() OVER (PARTITION BY departmentId ORDER BY salary DESC) AS rnk
    FROM Employee
)
SELECT d.name AS Department , c.name AS Employee , c.salary AS Salary
FROM cte AS c 
JOIN Department AS d
    ON c.departmentId = d.id
WHERE rnk<=3;
