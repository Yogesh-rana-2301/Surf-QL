# Summary: WHERE Clause

## Core idea

`WHERE` filters rows based on conditions so only matching records are returned or modified.

## Main syntax

```sql
SELECT column1, column2
FROM table_name
WHERE condition;
```

## Used with

- `SELECT` to fetch filtered records.
- `UPDATE` to modify only matching rows.
- `DELETE` to remove only matching rows.

## Common operators

- Comparison: `=`, `>`, `<`, `>=`, `<=`, `<>`
- Logical: `AND`, `OR`, `NOT`
- Pattern/range/set: `LIKE`, `BETWEEN`, `IN`

## Key points

- `BETWEEN` is inclusive of both boundaries.
- `LIKE 'L%'` matches values starting with `L`.
- Missing `WHERE` in `UPDATE`/`DELETE` can affect all rows.
