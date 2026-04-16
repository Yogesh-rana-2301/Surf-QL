# Summary: CREATE TABLE

## Core idea

`CREATE TABLE` defines a table structure by setting column names, data types, and optional constraints.

## Main syntax

```sql
CREATE TABLE table_name (
  column1 datatype(size),
  column2 datatype(size),
  ...
);
```

## Common constraints covered

- `PRIMARY KEY` for unique row identity.
- `CHECK` to validate allowed values.
- Optional: `NOT NULL`, `UNIQUE`, `DEFAULT`.

## Additional patterns

- Create only if missing:

```sql
CREATE TABLE IF NOT EXISTS table_name (...);
```

- Create from existing table data:

```sql
CREATE TABLE new_table AS
SELECT column1, column2
FROM existing_table;
```

## Key points

- Pick data types carefully for storage and performance.
- Use `DESC table_name;` to inspect the table structure.
- Use `ALTER TABLE` to change structure later.
