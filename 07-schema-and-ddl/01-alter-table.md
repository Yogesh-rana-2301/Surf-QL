# ALTER TABLE — Reshaping Tables Without Rebuilding Them

> **Interview Priority**: 🔴 Must Know

## What Is It?

`ALTER TABLE` is a DDL (Data Definition Language) command that modifies the **structure** of an existing table — without dropping and recreating it. You use it to add or remove columns, rename things, change data types, and manage constraints. Unlike `DROP + CREATE`, it preserves existing data (with important caveats around type changes).

---

## Syntax

```sql
-- Generic forms
ALTER TABLE table_name ADD COLUMN column_name datatype [constraints];
ALTER TABLE table_name DROP COLUMN column_name;
ALTER TABLE table_name RENAME COLUMN old_name TO new_name;

-- MySQL: change type / definition
ALTER TABLE table_name MODIFY COLUMN column_name new_datatype;

-- PostgreSQL: change type / definition
ALTER TABLE table_name ALTER COLUMN column_name TYPE new_datatype;

-- Rename the table itself
ALTER TABLE old_table_name RENAME TO new_table_name;        -- PostgreSQL / MySQL 8+
RENAME TABLE old_table_name TO new_table_name;              -- MySQL shorthand

-- Constraints
ALTER TABLE table_name ADD CONSTRAINT constraint_name constraint_def;
ALTER TABLE table_name DROP CONSTRAINT constraint_name;     -- PostgreSQL
ALTER TABLE table_name DROP INDEX constraint_name;          -- MySQL (for UNIQUE)
ALTER TABLE table_name DROP FOREIGN KEY fk_name;            -- MySQL (foreign keys)
```

---

## Key Concepts

- **DDL is auto-committed** in most databases — there is no ROLLBACK after an `ALTER TABLE` in MySQL. PostgreSQL is an exception: DDL runs inside a transaction and can be rolled back.
- **Column order** — SQL tables are logically unordered, but MySQL lets you use `AFTER col_name` or `FIRST` to control physical order. PostgreSQL does not support reordering without recreating the table.
- **NOT NULL + no default** — Adding a `NOT NULL` column to a table that already has rows will fail unless you supply a `DEFAULT` value (or the database allows a table-scan to fill existing rows first).
- **Data loss on type change** — Widening types (INT → BIGINT) is safe. Narrowing (VARCHAR(200) → VARCHAR(10)) or incompatible conversions (VARCHAR → INT) can **silently truncate or fail**. Always back up first.
- **Constraint naming matters** — Named constraints (`CONSTRAINT fk_dept FOREIGN KEY ...`) are much easier to drop later. Unnamed constraints auto-generate ugly system names.
- **Large tables** — On a table with millions of rows, `ADD COLUMN` can lock the table for minutes. Tools like `pt-online-schema-change` (MySQL) or `pg_repack` (PostgreSQL) handle this online.

---

## Examples

### 1. ADD COLUMN — add a phone number field to employees

```sql
ALTER TABLE employees
ADD COLUMN phone VARCHAR(20);

-- With a default so existing rows are NOT NULL-safe
ALTER TABLE employees
ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
```

### 2. DROP COLUMN — remove a column that is no longer needed

```sql
ALTER TABLE employees
DROP COLUMN phone;
```

> ⚠️ This permanently deletes all data in that column. There is no undo in MySQL.

### 3. RENAME COLUMN — rename `name` to `full_name`

```sql
-- PostgreSQL / MySQL 8.0+
ALTER TABLE employees
RENAME COLUMN name TO full_name;
```

```sql
-- MySQL < 8.0 (uses CHANGE, must repeat the full column definition)
ALTER TABLE employees
CHANGE COLUMN name full_name VARCHAR(100);
```

### 4. MODIFY / ALTER COLUMN — change salary from DECIMAL(10,2) to DECIMAL(15,2)

```sql
-- MySQL (safe widening — no data loss)
ALTER TABLE employees
MODIFY COLUMN salary DECIMAL(15, 2);

-- PostgreSQL
ALTER TABLE employees
ALTER COLUMN salary TYPE DECIMAL(15, 2);
```

**Unsafe narrowing example (avoid):**

```sql
-- ❌ Risk: truncates existing email values longer than 50 chars
ALTER TABLE employees
MODIFY COLUMN email VARCHAR(50);
```

### 5. ADD CONSTRAINT — add a foreign key

```sql
ALTER TABLE employees
ADD CONSTRAINT fk_emp_dept
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
  ON DELETE SET NULL;
```

### 6. ADD CONSTRAINT — enforce unique emails

```sql
ALTER TABLE employees
ADD CONSTRAINT uq_emp_email UNIQUE (email);
```

### 7. DROP CONSTRAINT

```sql
-- PostgreSQL
ALTER TABLE employees
DROP CONSTRAINT fk_emp_dept;

-- MySQL: foreign keys and unique indexes use different syntax
ALTER TABLE employees DROP FOREIGN KEY fk_emp_dept;
ALTER TABLE employees DROP INDEX uq_emp_email;
```

### 8. RENAME TABLE

```sql
-- PostgreSQL / MySQL 8+
ALTER TABLE employees RENAME TO staff;

-- MySQL shorthand
RENAME TABLE employees TO staff;
```

### 9. Multiple operations in one statement (MySQL only)

```sql
-- MySQL allows combining multiple alterations in a single ALTER TABLE
ALTER TABLE employees
  ADD COLUMN phone VARCHAR(20),
  DROP COLUMN is_active,
  MODIFY COLUMN salary DECIMAL(15, 2),
  ADD CONSTRAINT uq_email UNIQUE (email);
```

> PostgreSQL requires separate `ALTER TABLE` statements for each action.

---

## Dialect Differences (MySQL vs PostgreSQL)

| Operation | MySQL | PostgreSQL |
|---|---|---|
| Rename column | `RENAME COLUMN` (8.0+) or `CHANGE` | `RENAME COLUMN` |
| Change column type | `MODIFY COLUMN col TYPE` | `ALTER COLUMN col TYPE new_type` |
| Drop constraint | `DROP FOREIGN KEY` / `DROP INDEX` | `DROP CONSTRAINT name` |
| Rename table | `RENAME TABLE` or `ALTER TABLE ... RENAME` | `ALTER TABLE ... RENAME TO` |
| Multiple operations | ✅ In one statement | ❌ One per statement |
| DDL in transaction | ❌ Auto-committed | ✅ Can ROLLBACK |
| Column reorder | ✅ `AFTER col` / `FIRST` | ❌ Not supported |
| Set column default | `ALTER COLUMN col SET DEFAULT val` | `ALTER COLUMN col SET DEFAULT val` |
| Drop column default | `ALTER COLUMN col DROP DEFAULT` | `ALTER COLUMN col DROP DEFAULT` |

---

## Interview Tips

1. **"Is ALTER TABLE reversible?"** — In MySQL, no: DDL is auto-committed. In PostgreSQL, yes — DDL participates in transactions. This distinction surprises many candidates.

2. **"What happens when you add a NOT NULL column to a populated table?"** — It fails unless you provide a DEFAULT. A common workaround: `ADD COLUMN col TYPE DEFAULT val`, populate it, then `ALTER COLUMN col DROP DEFAULT` and add the NOT NULL constraint.

3. **"How do you rename a column in MySQL 5.7?"** — You must use `CHANGE COLUMN old_name new_name datatype` and repeat the full type definition. `RENAME COLUMN` was only added in MySQL 8.0.

4. **"What are the dangers of changing a column's data type?"** — Data truncation (narrowing length), implicit cast failures, index invalidation, and dependent view/function breakage. Always test on a copy first.

5. **"How would you add a column to a 500-million-row table with zero downtime?"** — Use online schema change tools (pt-online-schema-change, gh-ost for MySQL; `pg_repack` or native `ALTER TABLE … CONCURRENTLY` for indexes in PostgreSQL). Never run raw `ALTER TABLE` on hot production tables without a plan.

---

## ❓ Practice Questions

1. The `employees` table currently has `email VARCHAR(120)`. Write a statement to change it to `VARCHAR(200)`. Then write a separate statement to rename the column to `work_email`. Show both the MySQL and PostgreSQL versions.

2. A new business rule requires that every employee must have a `department_code CHAR(4) NOT NULL`. The `employees` table already has 500 rows. What is the correct sequence of `ALTER TABLE` statements to add this column safely without errors?

3. Write the SQL to add a `FOREIGN KEY` constraint on `performance.emp_id` referencing `employees.emp_id`, naming the constraint `fk_perf_emp`. Then write the statements to drop it — once in MySQL syntax and once in PostgreSQL syntax.

4. The `orders` table needs a `UNIQUE` constraint on the combination of `(customer_id, order_date, product_id)` to prevent duplicate order entries. Write the `ALTER TABLE` statement to add this composite unique constraint.

5. A developer accidentally renamed the `departments` table to `dept_backup`. Write the SQL to rename it back. Then explain: in MySQL, if you run this inside a `BEGIN` transaction and then `ROLLBACK`, will the rename be undone?
