# 04) FROM Clause

`FROM` tells SQL which table to read data from.
Without `FROM`, most queries cannot identify the data source.

## Basic Syntax

```sql
SELECT column_list
FROM table_name;
```

## Examples

Single table:

```sql
SELECT student_id, student_name
FROM students;
```

Using table alias:

```sql
SELECT s.student_name, s.city
FROM students AS s;
```

Multiple tables (preview for joins):

```sql
SELECT s.student_name, d.dept_name
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;
```

## Why FROM Matters in Interviews

Interviewers often test query execution order.
Logically, SQL reads source rows from `FROM` first, then applies filtering and projection.
