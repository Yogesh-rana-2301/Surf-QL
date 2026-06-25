# Summary: Aggregate Functions with JOIN and OVER Clause

## Prerequisites

- Aggregate functions in SQL
- SQL joins

## Core idea

Aggregate functions return a single summarized value for a group of rows.
To show aggregated values together with regular row-level columns, we commonly use:

1. Join with an aggregated subquery
2. Window functions using `OVER (PARTITION BY ...)`

## Example tables

### EMP

- `EMPNO` NUMBER(4)
- `ENAME` VARCHAR2(10)
- `JOB` VARCHAR2(9)
- `MGR` NUMBER(4)
- `HIREDATE` DATE
- `SAL` NUMBER(7,2)
- `COMM` NUMBER(7,2)
- `DEPTNO` NUMBER(2)

### DEPT

- `DEPTNO` NUMBER(2)
- `DNAME` VARCHAR2(14)
- `LOC` VARCHAR2(13)

## Required outputs

1. Show `ENAME`, `SAL`, `JOB` with `MAX`, `MIN`, `AVG`, `SUM` salary of employees having the same job.
2. Show department name with number of employees working in each department.

## 1) Solution using JOIN + aggregated subquery

```sql
SELECT e.ENAME,
       e.SAL,
       e.JOB,
       j.MAXSAL,
       j.MINSAL,
       j.AVGSAL,
       j.SUMSAL
FROM EMP e
INNER JOIN (
    SELECT JOB,
           MAX(SAL) AS MAXSAL,
           MIN(SAL) AS MINSAL,
           AVG(SAL) AS AVGSAL,
           SUM(SAL) AS SUMSAL
    FROM EMP
    GROUP BY JOB
) j
ON e.JOB = j.JOB;
```

What happens here:

- Inner subquery groups by `JOB` and computes aggregate salary metrics.
- Outer query joins each employee row with that job-level summary.
- Result shows row-level columns and job-level aggregate values together.

Sample output (for sample data):

```text
ENAME  | SAL  | JOB     | MAXSAL | MINSAL | AVGSAL  | SUMSAL
SCOTT  | 3300 | ANALYST | 3300   | 1925   | 2841.67 | 8525
HENRY  | 1925 | ANALYST | 3300   | 1925   | 2841.67 | 8525
FORD   | 3300 | ANALYST | 3300   | 1925   | 2841.67 | 8525
MILLER | 1430 | CLERK   | 3300   | 1045   | 1746.25 | 6985
```

## 2) Solution using OVER clause for department employee count

```sql
SELECT DISTINCT d.DNAME,
       COUNT(e.ENAME) OVER (PARTITION BY d.DEPTNO) AS EMP_COUNT
FROM DEPT d
LEFT JOIN EMP e
  ON e.DEPTNO = d.DEPTNO
ORDER BY EMP_COUNT DESC;
```

Why this works:

- `PARTITION BY d.DEPTNO` creates one partition per department.
- `COUNT(e.ENAME)` counts employees inside each department partition.
- `LEFT JOIN` keeps departments even when they have zero employees.
- `DISTINCT` avoids repeated department rows in the final output.

Sample output:

```text
DNAME      | EMP_COUNT
SALES      | 6
RESEARCH   | 5
ACCOUNTING | 3
OPERATIONS | 0
```

## Notes

- The join-subquery method is useful when you want one aggregate row per group, then attach it to detail rows.
- The `OVER` method keeps row-level context while still computing grouped metrics.
- `COUNT(e.ENAME)` ignores `NULL`, which helps show `0` for departments without employees.

## Key points

- Use aggregate subquery + join to combine grouped metrics with detail rows.
- Use `OVER (PARTITION BY ...)` for analytic calculations without collapsing rows.
- Choose `LEFT JOIN` when unmatched department rows must be preserved.
