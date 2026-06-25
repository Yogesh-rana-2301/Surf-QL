# UPDATE Statement — Modifying Existing Rows

> **Interview Priority**: 🔴 Must Know

## What Is It?

`UPDATE` modifies existing rows in a table. You specify which table to update, which columns to change (with `SET`), and — critically — **which rows to target** (with `WHERE`). Omitting `WHERE` updates every single row in the table, which is one of the most dangerous mistakes in SQL.

## Syntax

```sql
-- Update specific rows (always include WHERE)
UPDATE table_name
SET column1 = value1,
    column2 = value2
WHERE condition;

-- Update using a subquery in SET
UPDATE table_name
SET column1 = (SELECT ... FROM other_table WHERE ...)
WHERE condition;

-- Update using a subquery in WHERE
UPDATE table_name
SET column1 = value1
WHERE column2 IN (SELECT ... FROM other_table);
```

## Key Concepts

- **`WHERE` is mandatory in practice**: Without it, every row gets updated. A missing `WHERE` clause is responsible for countless production incidents.
- **`SET` accepts multiple columns**: Separate multiple column assignments with commas. They are all applied atomically in the same statement.
- **Expressions in `SET`**: You can reference the current column value — `SET salary = salary * 1.10` gives everyone a 10% raise.
- **Subqueries in `UPDATE`**: You can derive the new value or filter target rows using subqueries. This is how you do cross-table updates in standard SQL.
- **`UPDATE` respects constraints**: If the new value violates a `UNIQUE`, `CHECK`, or `FOREIGN KEY` constraint, the statement fails and rolls back.
- **`UPDATE` returns affected row count**: Most drivers/clients report "N rows affected". If 0 rows affected, your `WHERE` condition matched nothing — double-check it.
- **MySQL safe update mode**: MySQL Workbench enables `safe_updates` mode by default, which blocks UPDATE without a WHERE on a primary key. Disable with `SET SQL_SAFE_UPDATES = 0` when needed.

## Examples

```sql
-- 1. Update a single column for a specific employee
UPDATE employees
SET salary = 90000.00
WHERE emp_id = 2;
-- Only Aman Sharma's salary changes
```

```sql
-- 2. Update multiple columns at once
UPDATE employees
SET salary    = 95000.00,
    dept_id   = 10,
    hire_date = '2018-07-15'
WHERE emp_id = 2;
-- All three columns updated atomically in one statement
```

```sql
-- 3. Expression-based update — give all Engineering employees a 10% raise
UPDATE employees
SET salary = salary * 1.10
WHERE dept_id = 10;
-- Arjun: 120000→132000, Aman: 85000→93500, Dev: 78000→85800, Karan: 82000→90200
```

```sql
-- 4. Update based on a condition using another column
UPDATE orders
SET status = 'completed'
WHERE status = 'pending' AND order_date < '2024-02-01';
-- Marks old pending orders as completed
```

```sql
-- 5. Update with subquery in SET — set salary to department average
UPDATE employees
SET salary = (
    SELECT AVG(salary)
    FROM employees
    WHERE dept_id = 20
)
WHERE emp_id = 7;
-- Sets Neha's salary to HR department average
-- NOTE: In MySQL, you cannot reference the same table in a subquery being updated.
-- Use a derived table (nested subquery) to work around this:
UPDATE employees
SET salary = (
    SELECT avg_sal FROM (
        SELECT AVG(salary) AS avg_sal FROM employees WHERE dept_id = 20
    ) AS dept_avg
)
WHERE emp_id = 7;
```

```sql
-- 6. Update with subquery in WHERE — promote employees who have an 'A' rating
UPDATE employees
SET salary = salary * 1.15
WHERE emp_id IN (
    SELECT emp_id
    FROM performance
    WHERE rating = 'A'
);
-- Affects Aman Sharma (2022 'A') and Ravi Kumar (2022 & 2024 'A')
```

```sql
-- 7. Update to NULL (nullable column)
UPDATE employees
SET dept_id = NULL
WHERE emp_id = 11;
-- Removes department assignment for Meera Joshi
```

```sql
-- ⚠️  THE DANGER: UPDATE without WHERE
UPDATE employees
SET salary = 50000.00;
-- Every single one of the 12 employees now earns exactly 50000. No undo without a backup.
-- Always double-check your WHERE clause before running UPDATE.
```

```sql
-- 8. Safe pattern: preview with SELECT before UPDATE
-- Step 1: Verify which rows will be affected
SELECT emp_id, name, salary
FROM employees
WHERE dept_id = 40;
-- See: Zara (74000), Sneha (69000)

-- Step 2: Only then run the UPDATE
UPDATE employees
SET salary = salary * 1.05
WHERE dept_id = 40;
```

## Interview Tips

1. **Always preview with SELECT first**: Before any UPDATE, run the identical WHERE clause in a SELECT to verify you're targeting the right rows. This is a professional habit that prevents disasters.

2. **UPDATE without WHERE = all rows**: This is the most common SQL mistake in interviews. Always ask the interviewer: "Should this apply to specific rows?" before writing any UPDATE.

3. **MySQL self-referencing UPDATE workaround**: In MySQL, `UPDATE employees SET salary = (SELECT AVG(salary) FROM employees WHERE ...)` throws an error because you can't SELECT from the table you're updating. Wrap the subquery in a derived table to bypass this.

4. **Affected rows = 0 is not an error**: An UPDATE that affects 0 rows is syntactically valid — it just means no rows matched the WHERE condition. This can silently do nothing when you expected a change. Always verify.

5. **`UPDATE` vs `REPLACE INTO` in MySQL**: `REPLACE INTO` deletes the existing row and inserts a new one (triggers re-insert overhead, loses auto-assigned values). Prefer `UPDATE` with `ON DUPLICATE KEY UPDATE` for upserting instead.

## ❓ Practice Questions

1. Write an `UPDATE` statement to give all employees in the HR department (`dept_id = 20`) a 5% salary increase. How many rows would this affect?

2. A typo was made — customer `Komal Desai` (customer_id=8) is listed as being from `'Pune'` but should be `'Nagpur'`. Write the `UPDATE` to fix this.

3. Write an `UPDATE` to change the status of all `'cancelled'` orders in the `orders` table that were placed before `2024-03-01` to `'pending'`. Use both conditions in your WHERE clause.

4. Using a subquery in the WHERE clause, write an UPDATE to set the salary of all employees who have a performance rating of `'C'` to exactly ₹60,000. Use the `performance` table as the subquery source.

5. A developer accidentally runs `UPDATE orders SET status = 'cancelled';` without a WHERE clause. (a) What just happened? (b) If the database is in autocommit mode, can you recover? (c) What practices would prevent this mistake?
