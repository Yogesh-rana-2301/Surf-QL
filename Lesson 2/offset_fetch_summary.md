# Summary: OFFSET-FETCH Clause

## Core idea

`OFFSET-FETCH` is used for pagination in SQL. It lets us skip a number of rows and then return only a specific number of rows from an ordered result set.

## Main syntax

```sql
SELECT column_name(s)
FROM table_name
WHERE condition
ORDER BY column_name
OFFSET rows_to_skip ROWS;
```

```sql
SELECT column_name(s)
FROM table_name
ORDER BY column_name
OFFSET rows_to_skip ROWS
FETCH NEXT number_of_rows ROWS ONLY;
```

## Common use cases

- Skip the first few rows after sorting.
- Return one page of data at a time in web apps.
- Build server-side pagination for reports and tables.
- Return top, middle, or bottom slices of ordered data.

## Example patterns

- Skip the employee with the lowest salary:

```sql
SELECT Fname, Lname
FROM Employee
ORDER BY Salary
OFFSET 1 ROWS;
```

- Fetch rows from 3rd to 6th position:

```sql
SELECT Fname, Lname
FROM Employee
ORDER BY Salary
OFFSET 2 ROWS
FETCH NEXT 4 ROWS ONLY;
```

- Retrieve the bottom 2 rows by salary:

```sql
SELECT Fname, Lname
FROM Employee
ORDER BY Salary
OFFSET (SELECT COUNT(*) FROM Employee) - 2 ROWS
FETCH NEXT 2 ROWS ONLY;
```

## Key points

- `ORDER BY` is required when using `OFFSET` and `FETCH`.
- `OFFSET` cannot be negative.
- `FETCH` cannot be used alone; it must follow `OFFSET`.
- `TOP` cannot be used together with `OFFSET-FETCH` in the same query block.
- Row count expressions for `OFFSET` and `FETCH` should evaluate to integers.
