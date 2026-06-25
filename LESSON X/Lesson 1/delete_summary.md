# Summary: DELETE

## Core idea

`DELETE` removes rows from a table while keeping the table structure, indexes, and constraints.

## Main syntax

```sql
DELETE FROM table_name
WHERE condition;
```

## Typical usage

- Delete one row by ID.
- Delete multiple rows by a condition (for example, by department).
- Delete all rows by omitting `WHERE`.

## Important safety note

- Without `WHERE`, every row in the table is removed.

## Transactions and rollback

Because `DELETE` is a DML operation, changes can often be rolled back inside a transaction:

```sql
BEGIN TRANSACTION;
DELETE FROM table_name WHERE condition;
ROLLBACK;
```

## Key difference

- `DELETE` removes data rows.
- `DROP` removes the entire table object (structure + data).
