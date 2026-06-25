# Summary: SQL GROUP BY Clause

## Core idea

`GROUP BY` arranges rows into groups based on one or more columns.
It is commonly used with aggregate functions like `COUNT()`, `SUM()`, `AVG()`, `MAX()`, and `MIN()` to calculate results for each group.

## Main syntax

```sql
SELECT column1, aggregate_function(column2)
FROM table_name
WHERE condition
GROUP BY column1, column2;
```

- `aggregate_function`: function such as `SUM()`, `AVG()`, `COUNT()`.
- `table_name`: source table.
- `condition`: optional row filter before grouping (via `WHERE`).
- `column1, column2`: columns used to form groups.

## Basic example

```sql
SELECT Department, SUM(Salary) AS TotalSalary
FROM Employees
GROUP BY Department;
```

- Groups employees by department.
- Returns total salary for each department.

## Working patterns

### 1. Group by a single column

```sql
SELECT subject, COUNT(*) AS Student_Count
FROM Student
GROUP BY subject;
```

- Combines rows with the same `subject`.
- Counts students in each subject group.

### 2. Group by multiple columns

```sql
SELECT subject, year, COUNT(*) AS Student_Count
FROM Student
GROUP BY subject, year;
```

- Groups rows by each `subject` and `year` pair.
- Returns count for each subject-year combination.

## HAVING with GROUP BY

`HAVING` filters grouped results after aggregation.
`WHERE` filters individual rows before grouping.

### 1. Filter groups by total salary

```sql
SELECT age, SUM(sal) AS Total_Salary
FROM Employees
GROUP BY age
HAVING SUM(sal) > 50000;
```

- Groups employees by age.
- Returns only age groups whose total salary is above `50000`.

### 2. Filter groups by average salary

```sql
SELECT age, AVG(sal) AS Average_Salary
FROM Employees
GROUP BY age
HAVING AVG(sal) > 60000;
```

- Groups employees by age.
- Returns only age groups whose average salary is above `60000`.

## Important rule

Only grouped columns and aggregate expressions should appear in the `SELECT` list.

Valid pattern:

```sql
SELECT Department, COUNT(*)
FROM Employees
GROUP BY Department;
```

Invalid pattern idea:

```sql
-- Non-grouped, non-aggregated column in SELECT
SELECT Department, Name, COUNT(*)
FROM Employees
GROUP BY Department;
```

`Name` is neither grouped nor aggregated, so this is invalid in standard SQL.

## Key points

- `GROUP BY` creates summarized views of data.
- Use aggregates to compute metrics per group.
- Use `WHERE` before grouping, `HAVING` after grouping.
- For correctness, non-aggregated selected columns must be included in `GROUP BY`.
