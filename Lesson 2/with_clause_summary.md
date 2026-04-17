# Summary: WITH Clause (CTE)

## Core idea

`WITH` (Common Table Expression, CTE) creates a temporary named result set that can be used in the main query. It improves readability and helps break complex SQL into smaller steps.

## Main syntax

```sql
WITH cte_name (column1, column2, ...)
AS (
  SELECT column1, column2, ...
  FROM table_name
  WHERE condition
)
SELECT *
FROM cte_name;
```

## Common use cases

- Calculate intermediate values (for example average or minimum salary).
- Reuse computed results in the same query.
- Split complex logic into multiple named steps.
- Build chained CTEs where one CTE references another.

## Example patterns

- Above-average salary:

```sql
WITH AvgSalaryCTE (averageValue) AS (
  SELECT AVG(Salary)
  FROM Employees
)
SELECT EmployeeID, Name, Salary
FROM Employees
WHERE Salary > (SELECT averageValue FROM AvgSalaryCTE);
```

- Lowest salary:

```sql
WITH MinSalaryCTE (min_salary) AS (
  SELECT MIN(Salary)
  FROM Employees
)
SELECT e.EmployeeID, e.Name, e.Salary
FROM Employees e
WHERE e.Salary = (SELECT min_salary FROM MinSalaryCTE);
```

- Chained CTEs:

```sql
WITH DeptAvg AS (
  SELECT Department, AVG(Salary) AS AvgSalary
  FROM Employees
  GROUP BY Department
),
RankedEmployees AS (
  SELECT e.EmployeeID, e.Name, e.Department, e.Salary,
         RANK() OVER (PARTITION BY e.Department ORDER BY e.Salary DESC) AS SalaryRank
  FROM Employees e
  JOIN DeptAvg d ON e.Department = d.Department
)
SELECT *
FROM RankedEmployees
WHERE SalaryRank = 1;
```

## Key points

- The CTE query runs first and creates a temporary result set.
- The main query then uses that result like a table.
- CTE is only availabel to the query below, not to others or globally, for globally use views
- `RANK()` can return ties (multiple top earners in a department).
- CTEs improve maintainability compared to deeply nested subqueries.
