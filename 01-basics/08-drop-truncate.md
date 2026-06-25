# DROP & TRUNCATE — Removing Tables and Clearing Data

> **Interview Priority**: 🔴 Must Know

## What Is It?

`DROP TABLE` permanently removes a table's **structure and all its data** from the database. `TRUNCATE TABLE` removes **all rows instantly** but keeps the table structure intact. Together with `DELETE`, these three commands form a "removal spectrum" that every SQL developer must understand clearly — interviewers test this distinction in almost every interview.

## Syntax

```sql
-- Remove a table entirely (structure + data)
DROP TABLE table_name;
DROP TABLE IF EXISTS table_name;   -- safe: no error if table doesn't exist

-- Remove all rows instantly; keep structure
TRUNCATE TABLE table_name;
TRUNCATE table_name;               -- TABLE keyword is optional in MySQL

-- Remove an entire database (all tables + data inside)
DROP DATABASE database_name;
DROP DATABASE IF EXISTS database_name;
```

## Key Concepts

### DELETE vs TRUNCATE vs DROP — Full Comparison

| Feature | `DELETE` | `TRUNCATE` | `DROP` |
|---|---|---|---|
| **Type** | DML | DDL | DDL |
| **Removes rows?** | Yes (filtered or all) | Yes (all rows) | Yes (all rows) |
| **Removes structure?** | No | No | **Yes** |
| **Can use WHERE?** | ✅ Yes | ❌ No | ❌ No |
| **Transactional / Rollback?** | ✅ Yes (in MySQL/PG) | ❌ No (in MySQL) | ❌ No |
| **Fires row triggers?** | ✅ Yes | ❌ No | ❌ No |
| **Resets AUTO_INCREMENT?** | ❌ No | ✅ Yes | ✅ Yes (table recreated) |
| **Speed on large tables** | Slow (row-logged) | Very fast | Very fast |
| **FK constraint check?** | ✅ Yes | ✅ Yes (blocks if referenced) | ✅ Yes (blocks if referenced) |

> **Memory trick**: DELETE is surgical (precise), TRUNCATE is a flush (table stays, data gone), DROP is demolition (everything gone).

## Additional Key Points

- **`IF EXISTS` is production-safe**: `DROP TABLE IF EXISTS employees` doesn't throw an error if the table doesn't exist. Use this in setup scripts to make them re-runnable.
- **`DROP` order must respect FKs**: You cannot drop a parent table while a child table references it. Drop child tables first (or use `DROP TABLE ... CASCADE` in PostgreSQL).
- **`TRUNCATE` is DDL in MySQL, DML in PostgreSQL**: In PostgreSQL, `TRUNCATE` is transactional and can be rolled back. In MySQL, it cannot. Know the difference for the platform you're on.
- **`TRUNCATE` resets AUTO_INCREMENT to 1**: This is important for testing — after `TRUNCATE`, the next insert gets `id=1` again. `DELETE FROM table` does not reset it.
- **`DROP DATABASE` is irreversible**: Everything inside — tables, views, stored procedures, triggers — is gone instantly. Always take a backup before running this.

## Examples

```sql
-- 1. DROP TABLE — removes the table entirely
DROP TABLE IF EXISTS performance;
-- Table 'performance' no longer exists in the schema
-- SELECT * FROM performance; → ERROR: Table 'surfql.performance' doesn't exist
```

```sql
-- 2. DROP TABLE must respect foreign keys
DROP TABLE IF EXISTS departments;
-- ERROR 1217: Cannot delete or update a parent row: a foreign key constraint fails
-- employees.dept_id references departments.dept_id — drop employees first

DROP TABLE IF EXISTS performance;   -- no FK to departments
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS employees;     -- now safe to drop
DROP TABLE IF EXISTS departments;   -- parent dropped last
```

```sql
-- 3. TRUNCATE — wipe all data, keep structure
TRUNCATE TABLE performance;
-- All 8 performance rows deleted instantly
-- Table still exists with its schema intact
-- AUTO_INCREMENT resets to 1
-- SELECT * FROM performance; → (empty result set, 0 rows)
-- DESCRIBE performance; → still shows all columns and constraints
```

```sql
-- 4. Verify structure is preserved after TRUNCATE
TRUNCATE TABLE orders;
DESCRIBE orders;
-- Still shows: order_id, customer_id, product_id, amount, order_date, status
-- Foreign keys and constraints are still active
```

```sql
-- 5. DROP DATABASE
DROP DATABASE IF EXISTS surfql;
-- Removes the entire database — all 6 tables + all data
-- Server connection still works; you're just in no database now
```

```sql
-- 6. Demonstrating AUTO_INCREMENT reset difference
-- After INSERT 12 rows into orders:
DELETE FROM orders;              -- Deletes all rows; next INSERT gets order_id=13
TRUNCATE TABLE orders;           -- Deletes all rows; next INSERT gets order_id=1

-- This is why test environments prefer TRUNCATE — clean slate for IDs too
```

```sql
-- 7. PostgreSQL: TRUNCATE is transactional (unlike MySQL)
-- PostgreSQL only:
BEGIN;
TRUNCATE TABLE orders;
ROLLBACK;
SELECT COUNT(*) FROM orders;  -- Returns 12! Rows are back. Rollback worked.
```

```sql
-- 8. Practical setup script pattern
-- Always drop in reverse FK order, then recreate
DROP TABLE IF EXISTS performance;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments ( ... );
CREATE TABLE employees ( ... );
-- etc.
```

## Interview Tips

1. **The big three (DELETE, TRUNCATE, DROP)**: This is the single most commonly tested topic in SQL basics interviews. Memorize the table above. Key differentiators: DDL vs DML, rollback ability, AUTO_INCREMENT reset, trigger execution.

2. **TRUNCATE and foreign keys**: `TRUNCATE` fails if the table is referenced by a foreign key in another table — even if that other table is empty. You must drop the FK constraint, or truncate the child table first.

3. **MySQL vs PostgreSQL on TRUNCATE rollback**: In MySQL, `TRUNCATE` is DDL — it performs an implicit commit and cannot be rolled back. In PostgreSQL, `TRUNCATE` is transactional and can be rolled back with `ROLLBACK`. Know your platform.

4. **Why `DROP TABLE IF EXISTS` in migration scripts**: Without `IF EXISTS`, re-running a migration script throws an error on `DROP TABLE` if the table was already dropped. `IF EXISTS` makes the script idempotent.

5. **`TRUNCATE` vs `DELETE` for large tables**: If you need to empty a 50-million-row table, `DELETE` can take hours (logs every row). `TRUNCATE` takes milliseconds. But if you need to keep audit trails or fire triggers, `DELETE` is the only option.

## ❓ Practice Questions

1. A setup script needs to recreate all tables from scratch every time it's run. Write the `DROP TABLE IF EXISTS` statements in the correct order to avoid foreign key errors, given our dataset's schema.

2. You need to clear all test data from the `orders` table before running a new test suite, and you want `order_id` values to restart from 1. Which command would you use — `DELETE FROM orders` or `TRUNCATE TABLE orders` — and why?

3. Fill in the comparison table from memory for these three operations across the criteria: type (DDL/DML), rollback support, triggers, WHERE clause support, AUTO_INCREMENT reset.

4. You run `TRUNCATE TABLE departments` but get an error. Explain why this happens given our dataset schema, and write the correct sequence of operations to truncate `departments` safely.

5. A production database has a table `temp_calculations` with 20 million rows that needs to be emptied every night. Write the most appropriate SQL statement and explain your choice over the alternatives.
