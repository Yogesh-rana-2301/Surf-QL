# Summary: SQL UPDATE Statement

## Core idea

The `UPDATE` statement modifies existing data in a table by changing values in one or more columns.

The `WHERE` clause controls which rows are updated. Without `WHERE`, all rows are updated.

## Main syntax

```sql
UPDATE table_name
SET column1 = value1,
    column2 = value2,
    ...
WHERE condition;
```

- `table_name`: table to update.
- `SET`: columns and new values.
- `WHERE`: filter for target rows.

## Common use cases

- Update one column in a specific row.
- Update multiple columns in one query.
- Correct or standardize existing records.
- Apply mass updates intentionally (without `WHERE`).

## Example patterns

- Update salary for one employee:

```sql
UPDATE Employees
SET Salary = 65000
WHERE Name = 'Daniel';
```

- Update single column in `Customer`:

```sql
UPDATE Customer
SET Age = 25
WHERE CustomerName = 'Isabella';
```

- Update multiple columns together:

```sql
UPDATE Customer
SET CustomerName = 'John',
    Country = 'Spain'
WHERE CustomerID = 1;
```

- Update all rows (no `WHERE`):

```sql
UPDATE Customer
SET CustomerName = 'Mike';
```

## Key points

- `SET` assigns new values to columns.
- `WHERE` should be used carefully to avoid accidental full-table updates.
- Omitting `WHERE` updates every row in the table.
- Use `SELECT` with the same condition before `UPDATE` to verify affected rows.
