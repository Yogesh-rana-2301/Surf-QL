# Summary: DROP vs TRUNCATE

## Core idea

Both commands remove data, but they serve different purposes.

## DROP

```sql
DROP TABLE table_name;
DROP DATABASE database_name;
```

- Removes the full object (data + structure).
- Usually non-recoverable without backup.
- Used when the object is no longer needed.

## TRUNCATE

```sql
TRUNCATE TABLE table_name;
```

- Removes all rows only.
- Keeps table structure for reuse.
- Generally faster than row-by-row deletion for large tables.

## Practical difference

- Choose `DROP` when you want complete removal.
- Choose `TRUNCATE` when you want an empty table but keep schema.
