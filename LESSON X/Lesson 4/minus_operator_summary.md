# Summary: SQL MINUS Operator

> For ORACLE people only

## Core idea

The `MINUS` operator compares two `SELECT` query results and returns rows from the first query that are not present in the second query.
It removes common rows and keeps only unique rows from the first result set.

## How MINUS works

- First query result is treated as the base set.
- Second query result is subtracted from it.
- Matching rows are removed.
- Final output is distinct by default.

## Main syntax

```sql
SELECT column1, column2, ..., columnN
FROM table_name1
[WHERE condition]

MINUS

SELECT column1, column2, ..., columnN
FROM table_name2
[WHERE condition];
```

Rules:

- Both `SELECT` statements must return the same number of columns.
- Column order must be the same.
- Corresponding columns must have compatible data types.

## Example setup

```sql
CREATE TABLE Table1 (
  Name VARCHAR(50),
  Address VARCHAR(50),
  Age INT,
  Grade CHAR(1)
);

INSERT INTO Table1 (Name, Address, Age, Grade) VALUES
('Harsh', 'Delhi', 20, 'A'),
('Gaurav', 'Jaipur', 21, 'B'),
('Pratik', 'Mumbai', 21, 'A'),
('Dhanraj', 'Kolkata', 22, 'B');

CREATE TABLE Table2 (
  Name VARCHAR(50),
  Age INT,
  Phone VARCHAR(15),
  Grade CHAR(1)
);

INSERT INTO Table2 (Name, Age, Phone, Grade) VALUES
('Akash', 20, 'XXXXXXXXXX', 'A'),
('Dheeraj', 21, 'XXXXXXXXXX', 'B'),
('Vaibhav', 21, 'XXXXXXXXXX', 'A'),
('Dhanraj', 22, 'XXXXXXXXXX', 'B');
```

## Example query

```sql
SELECT Name, Age, Grade
FROM Table1
MINUS
SELECT Name, Age, Grade
FROM Table2;
```

Sample output:

```text
Name   | Age | Grade
Harsh  | 20  | A
Gaurav | 21  | B
Pratik | 21  | A
```

Explanation:
`MINUS` removes rows that appear in both query results.
`Dhanraj | 22 | B` exists in both tables (for selected columns), so it is excluded.
The remaining rows are unique to `Table1`.

## Database support note

- `MINUS` is supported in Oracle.
- SQL Server and PostgreSQL use `EXCEPT` for equivalent behavior.

Equivalent form in SQL Server/PostgreSQL:

```sql
SELECT Name, Age, Grade
FROM Table1
EXCEPT
SELECT Name, Age, Grade
FROM Table2;
```

## Key points

- `MINUS` returns rows from first query only.
- Common rows are removed.
- Output is distinct by default.
- Keep both query column lists aligned in count, order, and data type.
