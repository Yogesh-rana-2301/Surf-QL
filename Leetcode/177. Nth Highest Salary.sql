CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
  RETURN (
      # Write your MySQL query statement below.
        WITH c AS (
            SELECT DISTINCT salary , DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
            FROM Employee AS e
        )
        SELECT salary
        FROM c 
        WHERE rnk=n
  );
END
