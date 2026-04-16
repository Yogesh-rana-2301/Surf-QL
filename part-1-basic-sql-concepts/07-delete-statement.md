# 07) DELETE Statement

`DELETE` removes rows from a table.
Use `WHERE` carefully. Missing `WHERE` removes all rows.

## Syntax

```sql
DELETE FROM table_name
WHERE condition;
```

## Examples

Delete one student:

```sql
DELETE FROM students
WHERE student_id = 6;
```

Delete all students from one city:

```sql
DELETE FROM students
WHERE city = 'Delhi';
```

Delete all rows (table stays):

```sql
DELETE FROM students;
```

## Safe Usage Tips

- First run the same condition with `SELECT` to verify target rows.
- Wrap deletes in a transaction during critical operations.

```sql
START TRANSACTION;
DELETE FROM students WHERE student_id = 999;
ROLLBACK;
```

## Interview Comparison

- `DELETE`: row-level, can use `WHERE`, can be rolled back in transactions.
- `TRUNCATE`: fast full-table removal, no row-level filter.
