# Write your MySQL query statement below
WITH cte AS (
    SELECT p.managerId, e.id, e.name
    FROM Employee AS e
    JOIN Employee AS p 
        ON e.id = p.managerId
)
SELECT c.name
FROM cte AS c 
GROUP BY managerId , name
HAVING COUNT(*)>=5


/*





*/
