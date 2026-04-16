# 06) INSERT INTO

`INSERT INTO` adds new rows to a table.
Always specify column names to make queries safe and readable.

## Syntax

```sql
INSERT INTO table_name (column1, column2, ...)
VALUES (value1, value2, ...);
```

## Examples

Insert one row:

```sql
INSERT INTO students (student_id, student_name, age, city, dept_id)
VALUES (4, 'Riya', 22, 'Bengaluru', 30);
```

Insert multiple rows:

```sql
INSERT INTO students (student_id, student_name, age, city, dept_id)
VALUES
  (5, 'Dev', 20, 'Delhi', 10),
  (6, 'Meera', 21, 'Pune', 20);
```

## Best Practices

- Avoid omitting column list (`INSERT INTO table VALUES (...)`).
- Keep data types aligned with columns.
- For large imports, use batch inserts.

## Error Cases

- Duplicate primary key.
- Foreign key value missing in parent table.
- `NOT NULL` column value not provided.
