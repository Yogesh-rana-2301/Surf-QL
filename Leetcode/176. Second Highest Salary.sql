# Write your MySQL query statement below
SELECT MAX(salary) AS SecondHighestSalary
FROM Employee
WHERE salary < (
SELECT MAX(salary) FROM Employee
)





# Write your MySQL query statement below
WITH cte AS (
    SELECT id,salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM Employee
)
SELECT IF(COUNT(DISTINCT salary)=1,salary, NULL) AS SecondHighestSalary
FROM cte
WHERE rnk=2;
