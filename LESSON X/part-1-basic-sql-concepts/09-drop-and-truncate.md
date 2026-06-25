# 09) DROP and TRUNCATE

Both commands remove data quickly, but their scope is different.

## TRUNCATE

`TRUNCATE` removes all rows from a table and keeps table structure.

```sql
TRUNCATE TABLE students;
```

Characteristics:

- No `WHERE` support.
- Faster than row-by-row delete for large tables.
- Often resets auto-increment counters (dialect-dependent).

## DROP

`DROP` removes the entire table object (structure + data).

```sql
DROP TABLE students;
```

Also possible for database:

```sql
DROP DATABASE surfql_part1;
```

## DELETE vs TRUNCATE vs DROP

- `DELETE`: remove selected rows (or all rows), table remains.
- `TRUNCATE`: remove all rows only, table remains.
- `DROP`: remove the table/database object itself.

## Interview Tip

If you need to keep the table for future inserts, use `TRUNCATE`.
If the table is no longer needed, use `DROP`.
