# DELETE Statement — Removing Rows from a Table

> **Interview Priority**: 🔴 Must Know

## What Is It?

`DELETE FROM` removes one or more rows from a table. Like `UPDATE`, it **requires a `WHERE` clause in practice** — omitting it deletes every row in the table. Unlike `DROP TABLE` (which removes the table structure itself) or `TRUNCATE` (which wipes all rows instantly), `DELETE` is a DML operation that is transactional, logged row-by-row, and can be rolled back if inside a transaction.

## Syntax

```sql
-- Delete specific rows (always include WHERE)
DELETE FROM table_name
WHERE condition;

-- Delete using a subquery in WHERE
DELETE FROM table_name
WHERE column IN (
    SELECT column FROM other_table WHERE condition
);

-- Delete all rows (no WHERE — dangerous but valid)
DELETE FROM table_name;
```

## Key Concepts

- **`DELETE` is DML, not DDL**: It manipulates data, not structure. The table itself remains, just empty (if all rows deleted).
- **Fully transactional**: `DELETE` is logged row-by-row. Inside an explicit transaction (`BEGIN; DELETE ...; ROLLBACK;`), it can be undone.
- **Foreign key constraints block deletions**: If a parent row is referenced by a child table (e.g., deleting a department that still has employees), MySQL raises a foreign key violation error. You must delete/reassign child rows first — or cascade.
- **`ON DELETE CASCADE`**: A foreign key option where deleting a parent row automatically deletes all referencing child rows. Powerful but must be used carefully.
- **`DELETE` without WHERE ≠ `TRUNCATE`**: Both empty a table, but `DELETE` is slower (logs each row), fires row-level triggers, and can be rolled back. `TRUNCATE` is faster but cannot be rolled back in MySQL (DDL).
- **`LIMIT` with DELETE (MySQL)**: MySQL allows `DELETE FROM table WHERE ... LIMIT n` to cap how many rows are deleted — useful for batch deletions.

## Examples

```sql
-- 1. Delete a specific row by primary key
DELETE FROM performance
WHERE perf_id = 8;
-- Removes Sneha Reddy's 2024 performance record
```

```sql
-- 2. Delete with a compound WHERE condition
DELETE FROM orders
WHERE status = 'cancelled'
  AND order_date < '2024-03-01';
-- Removes: order_id=5 (Farhan, cancelled, Feb 2024)
```

```sql
-- 3. Delete using a subquery — remove orders for customers in Delhi
DELETE FROM orders
WHERE customer_id IN (
    SELECT customer_id
    FROM customers
    WHERE city = 'Delhi'
);
-- Deletes orders for Farhan (customer_id=3) and Ishaan (customer_id=6)
```

```sql
-- 4. Delete from a child table first, then parent
-- Attempting to delete Engineering dept while employees exist → FK error:
DELETE FROM departments WHERE dept_id = 10;
-- ERROR 1451: Cannot delete a parent row: a foreign key constraint fails

-- Correct approach: remove/reassign children first
UPDATE employees SET dept_id = NULL WHERE dept_id = 10;
DELETE FROM departments WHERE dept_id = 10;
```

```sql
-- 5. Cascade delete (schema-level, set at CREATE TABLE)
-- If orders had: FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
DELETE FROM customers WHERE customer_id = 1;
-- Automatically deletes orders 1 and 2 (Amit Bose's orders) as well
```

```sql
-- 6. DELETE with LIMIT (MySQL) — delete in safe batches
DELETE FROM orders
WHERE status = 'cancelled'
LIMIT 5;
-- Deletes at most 5 cancelled orders per run — safe for large tables
```

```sql
-- 7. Transactional DELETE — can be rolled back
START TRANSACTION;
DELETE FROM employees WHERE dept_id = 40;
-- Check what was deleted
SELECT * FROM employees WHERE dept_id = 40;  -- should return 0 rows
ROLLBACK;  -- undo the delete
SELECT * FROM employees WHERE dept_id = 40;  -- rows are back!
```

```sql
-- ⚠️  THE DANGER: DELETE without WHERE
DELETE FROM employees;
-- All 12 employee rows are gone. Table structure remains, but all data is lost.
-- ALWAYS run your WHERE clause as a SELECT first.
```

```sql
-- TRUNCATE comparison (same effect as DELETE without WHERE, but faster and non-transactional)
TRUNCATE TABLE orders;
-- Instantly removes all 12 orders. Cannot be rolled back in MySQL.
-- Auto-increment counter resets to 1.
```

## Interview Tips

1. **DELETE vs TRUNCATE vs DROP**: This is asked in almost every SQL interview. The core difference is: DELETE is DML (transactional, row-logged, can rollback), TRUNCATE is DDL (faster, resets auto-increment, cannot rollback in MySQL), DROP removes the table structure entirely.

2. **Foreign key cascades**: Know that `ON DELETE CASCADE` vs `ON DELETE RESTRICT` vs `ON DELETE SET NULL` are three different strategies for handling FK violations. `RESTRICT` (default) blocks deletion, `CASCADE` propagates it, `SET NULL` nullifies the FK column.

3. **DELETE is slow on large tables**: Because it logs every deleted row, deleting 10 million rows with `DELETE` is very slow. `TRUNCATE` is the right tool when you want to empty an entire table.

4. **Self-referencing FK delete order**: In `employees`, `manager_id` references `emp_id` in the same table. To delete a manager, you must first null out all `manager_id` references to that employee, then delete the manager.

5. **`DELETE` fires row-level triggers, `TRUNCATE` does not**: If your table has `BEFORE DELETE` or `AFTER DELETE` triggers, `TRUNCATE` bypasses them entirely. This matters for audit logging.

## ❓ Practice Questions

1. Write a `DELETE` statement to remove the performance record for `emp_id = 3` (Priya Nair) from the `performance` table. Which `perf_id` row does this correspond to?

2. Delete all `'pending'` orders placed before `'2024-03-01'` from the `orders` table. Write the query and identify which `order_id`s would be removed.

3. Write a query to delete all customers from the `customers` table who have **no orders** (i.e., their `customer_id` does not appear in the `orders` table). Use a subquery with `NOT IN`.

4. You try to delete `dept_id = 20` (HR) from `departments`, but it fails with a foreign key constraint error. Explain why, and write the two-step solution to safely delete the HR department and reassign its employees.

5. Compare `DELETE FROM orders;` vs `TRUNCATE TABLE orders;` — explain the difference in terms of: (a) transaction rollback, (b) auto-increment reset, (c) trigger execution, and (d) performance.
