# Summary: DENSE_RANK()

## Core idea

`DENSE_RANK()` is a SQL window function that assigns rank values based on ordering.

Rows with equal values get the same rank, and the next rank is consecutive (no gaps).

## Main syntax

```sql
SELECT
  column1,
  column2,
  DENSE_RANK() OVER (
    PARTITION BY group_column
    ORDER BY sort_column DESC
  ) AS dense_rank_value
FROM table_name;
```

- `PARTITION BY` splits data into groups (optional).
- `ORDER BY` defines ranking order (required inside `OVER`).

## Common use cases

- Rank employees by salary within each department.
- Build leaderboards where ties should not create rank gaps.
- Get top `n` items per category.
- Compare ranking behavior with `RANK()` and `ROW_NUMBER()`.

## Example patterns

- Department-wise salary ranking:

```sql
SELECT
  EmployeeID,
  Name,
  Department,
  Salary,
  DENSE_RANK() OVER (
    PARTITION BY Department
    ORDER BY Salary DESC
  ) AS SalaryRank
FROM Employees;
```

- Top 3 salary ranks per department:

```sql
WITH RankedEmployees AS (
  SELECT
    EmployeeID,
    Name,
    Department,
    Salary,
    DENSE_RANK() OVER (
      PARTITION BY Department
      ORDER BY Salary DESC
    ) AS SalaryRank
  FROM Employees
)
SELECT *
FROM RankedEmployees
WHERE SalaryRank <= 3;
```

- Compare ranking functions:

```sql
SELECT
  Name,
  Salary,
  ROW_NUMBER() OVER (ORDER BY Salary DESC) AS row_num,
  RANK() OVER (ORDER BY Salary DESC) AS rank_value,
  DENSE_RANK() OVER (ORDER BY Salary DESC) AS dense_rank_value
FROM Employees;
```

## Key points

- `DENSE_RANK()` gives same rank to tied values.
- Unlike `RANK()`, it does not skip rank numbers after ties.
- Unlike `ROW_NUMBER()`, ties do not get unique sequential numbers.
- It is best when tied results should share rank and numbering must stay compact.
