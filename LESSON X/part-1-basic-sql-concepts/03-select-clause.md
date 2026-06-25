# 03) SELECT Clause

`SELECT` is used to retrieve data from a table.
It is the most frequently used SQL command in interviews and coding rounds.

## Basic Syntax

```sql
SELECT column1, column2
FROM table_name;
```

## Examples

Fetch all columns:

```sql
SELECT *
FROM students;
```

Fetch specific columns:

```sql
SELECT student_name, city
FROM students;
```

Remove duplicates:

```sql
SELECT DISTINCT city
FROM students;
```

## Useful Variations

Aliasing columns:

```sql
SELECT student_name AS name, dept_id AS department
FROM students;
```

Add calculated column:

```sql
SELECT student_name, age, age + 1 AS age_next_year
FROM students;
```

## Common Mistakes

- Using `SELECT *` in production queries when only a few columns are needed.
- Forgetting that SQL engines may return rows in arbitrary order unless `ORDER BY` is used.
