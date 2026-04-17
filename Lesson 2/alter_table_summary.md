# Summary: SQL ALTER TABLE Statement

## Core idea

The ALTER TABLE statement modifies an existing table structure without deleting the table.

It is used when database requirements change and schema updates are needed while preserving existing data.

## Main syntax

```sql
ALTER TABLE table_name
ADD column_name datatype;
```

```sql
ALTER TABLE table_name
DROP COLUMN column_name;
```

```sql
ALTER TABLE table_name
MODIFY COLUMN column_name datatype;
```

```sql
ALTER TABLE table_name
RENAME COLUMN old_name TO new_name;
```

```sql
ALTER TABLE table_name
RENAME TO new_table_name;
```

## Common use cases

- Add new columns to store additional data.
- Change a column definition (data type, size, constraints).
- Remove unused columns.
- Rename columns for clarity.
- Rename whole tables to match new naming standards.

## Example patterns

- Rename table from Employees to Staff:

```sql
ALTER TABLE Employees
RENAME TO Staff;
```

- Add Email column:

```sql
ALTER TABLE Staff
ADD Email VARCHAR(100);
```

- Modify Address column type/size:

```sql
ALTER TABLE Staff
MODIFY COLUMN Address VARCHAR(100);
```

- Drop Grade column:

```sql
ALTER TABLE Staff
DROP COLUMN Grade;
```

- Rename Name column to EmployeeName:

```sql
ALTER TABLE Staff
RENAME COLUMN Name TO EmployeeName;
```

## Dialect note

ALTER syntax differs by SQL engine:

- SQL Server commonly uses `ALTER COLUMN` (instead of `MODIFY COLUMN`).
- MySQL supports `MODIFY COLUMN`.
- PostgreSQL supports `ALTER COLUMN ... TYPE` for type changes.

## Key points

- ALTER TABLE changes schema, not row values.
- Use caution with DROP operations because removed column data is lost.
- Always back up or test schema changes before running on production data.
- Renaming table/columns preserves existing stored data.
