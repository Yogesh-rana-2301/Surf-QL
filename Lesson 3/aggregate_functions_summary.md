# Summary: SQL Aggregate Functions

## Core idea

Aggregate functions summarize multiple rows into a single result value, which helps analyze trends and patterns in large datasets.

## Main syntax

```sql
AGGREGATE_FUNCTION(column_name)
```

Common usage inside a query:

```sql
SELECT AGGREGATE_FUNCTION(column_name)
FROM table_name;
```

## Important behavior

- Aggregate functions return one value after processing many rows.
- Most aggregate functions ignore `NULL` values.
- `COUNT(*)` is the exception and counts all rows, including rows with `NULL` values.
- Aggregates are often combined with `GROUP BY`, `HAVING`, and `ORDER BY` for analysis.

## Common aggregate functions

### 1. `COUNT()`

Used to count rows or values.

```sql
-- Total number of records
SELECT COUNT(*) AS TotalRecords
FROM Employee;

-- Count of non-NULL salaries
SELECT COUNT(Salary) AS NonNullSalaries
FROM Employee;

-- Count of unique non-NULL salaries
SELECT COUNT(DISTINCT Salary) AS UniqueSalaries
FROM Employee;
```

- `COUNT(*)` counts all rows.
- `COUNT(column_name)` counts only non-`NULL` values in that column.
- `COUNT(DISTINCT column_name)` counts unique non-`NULL` values.

### 2. `SUM()`

Used to calculate the total of a numeric column.

```sql
-- Total salary
SELECT SUM(Salary) AS TotalSalary
FROM Employee;

-- Sum of unique salaries
SELECT SUM(DISTINCT Salary) AS DistinctSalarySum
FROM Employee;
```

- `SUM(Salary)` adds all non-`NULL` salary values.
- `SUM(DISTINCT Salary)` adds only unique non-`NULL` salary values.

### 3. `AVG()`

Used to calculate the average of a numeric column.

```sql
-- Average salary
SELECT AVG(Salary) AS AverageSalary
FROM Employee;

-- Average of unique salaries
SELECT AVG(DISTINCT Salary) AS DistinctAvgSalary
FROM Employee;
```

- `AVG(Salary)` computes average over all non-`NULL` values.
- `AVG(DISTINCT Salary)` computes average over unique non-`NULL` values.

### 4. `MIN()` and `MAX()`

Used to find the smallest and largest values in a column.

```sql
-- Highest salary
SELECT MAX(Salary) AS HighestSalary
FROM Employee;

-- Lowest salary
SELECT MIN(Salary) AS LowestSalary
FROM Employee;
```

- `MAX()` returns the highest non-`NULL` value.
- `MIN()` returns the lowest non-`NULL` value.

## Quick grouping pattern

```sql
SELECT Department, AVG(Salary) AS AvgSalary
FROM Employee
GROUP BY Department
HAVING AVG(Salary) > 50000
ORDER BY AvgSalary DESC;
```

This pattern shows how aggregates can be used with:

- `GROUP BY` to summarize per group,
- `HAVING` to filter groups,
- `ORDER BY` to sort analyzed results.

## Key points

- Aggregates reduce many rows to a meaningful summary metric.
- `DISTINCT` can be applied inside aggregates to avoid duplicate impact.
- `NULL` handling is critical for interpreting results correctly.
- Combine aggregates with grouping clauses for deeper analysis.
