# Summary: SQL INTERSECT and EXCEPT Clause

## Core idea

`INTERSECT` and `EXCEPT` are set operations used to compare results from two `SELECT` queries.

- `INTERSECT` returns only rows that exist in both queries.
- `EXCEPT` returns rows that exist in the first query but not in the second query.

By default, both operations return distinct rows.

## Rules for using INTERSECT and EXCEPT

- Both `SELECT` queries must return the same number of columns.
- Column order must be the same in both queries.
- Corresponding columns should use compatible data types.
- `WHERE` conditions are applied before set comparison.

## Main syntax

```sql
SELECT column1, column2, ...
FROM table1
WHERE condition

INTERSECT

SELECT column1, column2, ...
FROM table2
WHERE condition;
```

```sql
SELECT column1, column2, ...
FROM table1
WHERE condition

EXCEPT

SELECT column1, column2, ...
FROM table2
WHERE condition;
```

## Example setup

```sql
CREATE TABLE Employee_Details (
  ID INT,
  Name VARCHAR(50),
  Age INT,
  City VARCHAR(50)
);

INSERT INTO Employee_Details (ID, Name, Age, City) VALUES
(1, 'Suresh', 24, 'Delhi'),
(2, 'Ramesh', 23, 'Pune'),
(3, 'Kashish', 34, 'Agra');

CREATE TABLE Employee_Bonus (
  Bonus_ID INT,
  Employee_ID INT,
  Bonus INT
);

INSERT INTO Employee_Bonus (Bonus_ID, Employee_ID, Bonus) VALUES
(43, 1, 20000),
(45, 3, 30000);
```

## Example 1: INTERSECT to find common rows

```sql
SELECT e.ID, e.Name, b.Bonus
FROM Employee_Details e
LEFT JOIN Employee_Bonus b
  ON e.ID = b.Employee_ID

INTERSECT

SELECT e.ID, e.Name, b.Bonus
FROM Employee_Details e
RIGHT JOIN Employee_Bonus b
  ON e.ID = b.Employee_ID;
```

Sample output:

```text
ID | Name    | Bonus
1  | Suresh  | 20000
3  | Kashish | 30000
```

Explanation:
The left join includes all employees, while the right join includes all bonus records.
`INTERSECT` keeps only rows common to both results, which are employees who have matching bonus entries.

## Example 2: EXCEPT to find rows only in first query

```sql
SELECT e.ID, e.Name, b.Bonus
FROM Employee_Details e
LEFT JOIN Employee_Bonus b
  ON e.ID = b.Employee_ID

EXCEPT

SELECT e.ID, e.Name, b.Bonus
FROM Employee_Details e
RIGHT JOIN Employee_Bonus b
  ON e.ID = b.Employee_ID;
```

Sample output:

```text
ID | Name   | Bonus
2  | Ramesh | NULL
```

Explanation:
The first query has all employees, including those without bonus.
The second query focuses on rows tied to bonus records.
`EXCEPT` returns rows present in the first result but missing from the second, so employee `Ramesh` appears with `NULL` bonus.

## Practical use cases

- Find common records across two datasets (`INTERSECT`).
- Find missing records between two datasets (`EXCEPT`).
- Validate data consistency between tables.
- Compare filtered result sets quickly without complex subqueries.

## Key points

- `INTERSECT` = common rows.
- `EXCEPT` = rows in first query only.
- Both return distinct rows by default.
- Always align selected columns in count, order, and data type.
