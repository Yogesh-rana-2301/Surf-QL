# Summary: SELECT

## Core idea

`SELECT` retrieves data from one or more tables in rows and columns.

## Main syntax

```sql
SELECT column1, column2
FROM table_name;
```

## Common variants

- All columns: `SELECT * FROM table_name;`
- Conditional filtering: `WHERE`
- Sorting: `ORDER BY`
- Grouping and aggregation: `GROUP BY`
- Group filtering: `HAVING`
- Unique values: `DISTINCT`

## Key points

- Use specific column lists instead of `*` when possible.
- Use `WHERE` before grouping to reduce data early.
- Use `HAVING` for conditions on grouped/aggregated results.
