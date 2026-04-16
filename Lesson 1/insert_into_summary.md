# Summary: INSERT INTO

## Core idea

`INSERT INTO` adds new records to a table.

## Main syntax

- Insert full row:

```sql
INSERT INTO table_name
VALUES (value1, value2, ...);
```

- Insert specific columns:

```sql
INSERT INTO table_name (column1, column2)
VALUES (value1, value2);
```

## Multi-row insert

```sql
INSERT INTO table_name (column1, column2)
VALUES
  (value1, value2),
  (value3, value4);
```

## Insert from another table

- Copy all columns:

```sql
INSERT INTO target_table
SELECT * FROM source_table;
```

- Copy selected columns or rows:

```sql
INSERT INTO target_table (col1, col2)
SELECT col1, col2
FROM source_table
WHERE condition;
```

## Key points

- Column order must match value order.
- Specifying column names makes queries safer and clearer.
- Multi-row insert is more efficient than many single inserts.
