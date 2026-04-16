# 05) WHERE Clause

`WHERE` filters rows based on conditions.
It is used in `SELECT`, `UPDATE`, and `DELETE` queries.

## Basic Syntax

```sql
SELECT column_list
FROM table_name
WHERE condition;
```

## Examples

Students from Delhi:

```sql
SELECT student_name, city
FROM students
WHERE city = 'Delhi';
```

Students older than 20:

```sql
SELECT student_name, age
FROM students
WHERE age > 20;
```

Multiple conditions:

```sql
SELECT student_name, city, age
FROM students
WHERE city = 'Mumbai' AND age >= 20;
```

## Important Notes

- Text values use single quotes.
- Numeric values usually do not require quotes.
- `NULL` comparisons must use `IS NULL` or `IS NOT NULL`, not `= NULL`.

```sql
SELECT *
FROM students
WHERE dept_id IS NULL;
```
