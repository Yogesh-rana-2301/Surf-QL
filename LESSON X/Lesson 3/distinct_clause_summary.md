# Summary: SQL DISTINCT Clause

## Core idea

`DISTINCT` removes duplicate values from query results and returns only unique records for the selected column(s).

## Main syntax

```sql
SELECT DISTINCT column1, column2, ...
FROM table_name;
```

- `column1, column2, ...`: column names to evaluate for uniqueness.
- `table_name`: source table.

## Important behavior

- With one column, `DISTINCT` returns unique values from that column.
- With multiple columns, `DISTINCT` returns unique combinations across those columns.
- `DISTINCT` can be combined with `ORDER BY`.
- `DISTINCT` can be used inside aggregate functions like `COUNT(DISTINCT column)`.
- Multiple `NULL` values are treated as the same value and appear once in output.

## Example patterns

- Unique departments:

```sql
SELECT DISTINCT Department
FROM Employees;
```

- Unique student names:

```sql
SELECT DISTINCT NAME
FROM students;
```

- Unique combinations of name and age:

```sql
SELECT DISTINCT NAME, AGE
FROM students;
```

- Unique ages sorted ascending:

```sql
SELECT DISTINCT AGE
FROM students
ORDER BY AGE;
```

- Count unique roll numbers:

```sql
SELECT COUNT(DISTINCT ROLL_NO)
FROM Students;
```

## NULL example

```sql
INSERT INTO students (ROLL_NO, NAME, ADDRESS, PHONE, AGE)
VALUES
  (13, 'John Doe', '123 Unknown Street', '9876543216', NULL),
  (14, 'James Brown', '129 Unknown Street', '9876554317', NULL);

SELECT DISTINCT AGE
FROM students;
```

Only one `NULL` appears in the result because `DISTINCT` treats all `NULL` entries as the same value.

## Key points

- Use `DISTINCT` when you need unique results.
- For multi-column queries, uniqueness is checked on the full column combination.
- `COUNT(DISTINCT column)` is useful for counting unique entities.
- `DISTINCT` does not remove rows globally unless all selected column values are identical.
