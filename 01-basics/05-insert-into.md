# INSERT INTO — Adding Rows to a Table

> **Interview Priority**: 🔴 Must Know

## What Is It?

`INSERT INTO` adds one or more new rows to a table. You can insert literal values directly, copy rows from another table using a `SELECT`, or insert multiple rows in a single statement. Every insert must satisfy all constraints (NOT NULL, UNIQUE, CHECK, FOREIGN KEY) — violations cause the statement to fail and roll back.

## Syntax

```sql
-- Insert a single row (explicit column list — recommended)
INSERT INTO table_name (col1, col2, col3)
VALUES (val1, val2, val3);

-- Insert without column list (must supply ALL columns in order — fragile)
INSERT INTO table_name
VALUES (val1, val2, val3, ...);

-- Insert multiple rows in one statement
INSERT INTO table_name (col1, col2, col3)
VALUES
    (val1a, val2a, val3a),
    (val1b, val2b, val3b),
    (val1c, val2c, val3c);

-- Insert from a SELECT (copy rows from another table)
INSERT INTO table_name (col1, col2)
SELECT col1, col2
FROM other_table
WHERE condition;
```

## Key Concepts

- **Always specify column names**: `INSERT INTO employees (emp_id, name, salary)` is safer than relying on column order. If a new column is added to the table, positional inserts break.
- **Omitted columns get their DEFAULT or NULL**: If you omit a column that has `DEFAULT 'pending'`, that default is used. If it has no default and is `NOT NULL`, the insert fails.
- **Multi-row insert is more efficient**: One `INSERT ... VALUES (row1), (row2), (row3)` is significantly faster than three separate `INSERT` statements — fewer network round-trips and transaction overheads.
- **`INSERT INTO ... SELECT`** is powerful for data migrations, populating summary tables, or copying filtered subsets of data.
- **Auto-increment columns**: Skip or pass `NULL` for `AUTO_INCREMENT` columns — the database assigns the next value automatically.
- **Constraint violations roll back the entire statement**: A single bad row in a multi-row insert fails the whole batch (unless you use `INSERT IGNORE` or `ON DUPLICATE KEY UPDATE` in MySQL).

## Examples

```sql
-- 1. Insert a single department (explicit columns — best practice)
INSERT INTO departments (dept_id, dept_name, location)
VALUES (50, 'Legal', 'Hyderabad');
```

```sql
-- 2. Insert a single employee — omitting manager_id uses NULL (nullable column)
INSERT INTO employees (emp_id, name, dept_id, manager_id, salary, hire_date, email)
VALUES (13, 'Anaya Kapoor', 10, 2, 72000.00, '2026-06-01', 'anaya.kapoor@company.com');
```

```sql
-- 3. Insert with AUTO_INCREMENT (pass NULL for the PK column)
-- Suppose audit_log has AUTO_INCREMENT on log_id:
INSERT INTO audit_log (emp_id, action, logged_at)
VALUES (2, 'Updated salary', NOW());
-- log_id is assigned automatically by the database
```

```sql
-- 4. Multi-row insert — inserting three products at once
INSERT INTO products (product_id, product_name, category, price)
VALUES
    (9,  'Bluetooth Speaker', 'Electronics', 4999.00),
    (10, 'Formal Shirt',      'Clothing',    1899.00),
    (11, 'Green Tea 100g',    'Food',         349.00);
-- One statement, three rows — far more efficient than three separate INSERTs
```

```sql
-- 5. INSERT INTO ... SELECT — copy all Engineering employees to an archive table
-- (Assume archive_employees has the same schema as employees)
INSERT INTO archive_employees (emp_id, name, dept_id, manager_id, salary, hire_date, email)
SELECT emp_id, name, dept_id, manager_id, salary, hire_date, email
FROM employees
WHERE dept_id = 10;
-- Copies: Arjun, Aman, Dev, Karan
```

```sql
-- 6. INSERT INTO ... SELECT with transformation
-- Populate a bonus_payments table from performance data
INSERT INTO bonus_payments (emp_id, year, bonus_amount)
SELECT emp_id, year, bonus
FROM performance
WHERE rating = 'A';
-- Only A-rated employees: Aman (2022), Ravi (2022 & 2024)
```

```sql
-- 7. INSERT IGNORE — skips rows that violate UNIQUE constraint (MySQL)
INSERT IGNORE INTO customers (customer_id, name, city, email)
VALUES (1, 'Amit Bose', 'Mumbai', 'amit.bose@gmail.com');
-- customer_id=1 already exists; IGNORE silently skips it

-- 8. ON DUPLICATE KEY UPDATE — upsert pattern (MySQL)
INSERT INTO performance (perf_id, emp_id, year, rating, bonus)
VALUES (9, 2, 2024, 'A', 13000.00)
ON DUPLICATE KEY UPDATE rating = 'A', bonus = 13000.00;
-- If perf_id=9 exists, updates it; otherwise inserts
```

```sql
-- 9. What a constraint violation looks like
INSERT INTO employees (emp_id, name, dept_id, manager_id, salary, hire_date, email)
VALUES (2, 'Duplicate', 10, 1, 60000, '2026-01-01', 'new@company.com');
-- ERROR: Duplicate entry '2' for key 'PRIMARY'
-- The entire INSERT statement is rolled back

INSERT INTO orders (order_id, customer_id, product_id, amount, order_date, status)
VALUES (13, 99, 1, 5000, '2026-01-01', 'completed');
-- ERROR: Cannot add or update a child row: foreign key constraint fails
-- customer_id=99 does not exist in customers table
```

## Interview Tips

1. **Always name your columns in INSERT**: Positional inserts (`INSERT INTO t VALUES (...)`) are fragile. If the table gets a new column or column order changes, the insert silently writes wrong data or errors out. Named columns make inserts self-documenting and resilient.

2. **`INSERT INTO ... SELECT` does not need VALUES**: A common mistake is writing `INSERT INTO ... SELECT VALUES (...)`. The `SELECT` itself provides the rows — no `VALUES` keyword.

3. **Multi-row inserts vs. single inserts**: In an interview about performance, mention that batching inserts reduces network round-trips and transaction overhead. However, very large batches can hold locks for too long — balance batch size (typically 500–1000 rows).

4. **What happens on constraint violation**: By default, a constraint violation causes the entire statement to fail and roll back. MySQL's `INSERT IGNORE` silently skips bad rows; `ON DUPLICATE KEY UPDATE` handles the upsert pattern. Know these variants.

5. **Difference between `NULL` and omitting a column**: If you omit a column in `INSERT`, it gets the column's `DEFAULT` value. If there's no default and the column is `NOT NULL`, it fails. If the column is nullable, it gets `NULL`. These are three different behaviors.

## ❓ Practice Questions

1. Insert a new customer — `Tanvi Shah`, from `Ahmedabad`, with email `tanvi.shah@gmail.com` — into the `customers` table. Assign her `customer_id = 9`.
```sql
INSERT INTO customers (name, city, email, customer_id)
VALUES 
     ('Tanvi Shah', 'Ahmedabad','tanvi.shah@gmail.com', 9)
;
```

3. Write a single `INSERT` statement to add three new orders for customer_id 7 (Jaya Krishnan, who currently has no orders): one completed order for product 4, one pending order for product 7, and one cancelled order for product 2. Assign `order_id` values 13, 14, 15.
```sql
INSERT INTO orders
(order_id, customer_id, product_id, status)
VALUES
(13, 7, 4, 'completed'),
(14, 7, 7, 'pending'),
(15, 7, 2, 'cancelled');

```


5. Using `INSERT INTO ... SELECT`, populate a new table called `high_earners (emp_id, name, salary)` with all employees from the `employees` table who earn more than ₹80,000.
```sql
INSERT INTO high_earners (emp_id, name, salary)
SELECT (emp_id, name, salary)
FROM employees
WHERE salary>80000;
;
```


7. What happens if you try to insert a row into `orders` with a `customer_id` that doesn't exist in `customers`? What constraint causes this, and what error behavior do you expect?
```md
foreign key constrant is not satified, and it says about foreign key value for somethign which dont exist in the customers table.
```

9. Write an upsert for the `performance` table: insert a record for `emp_id=6, year=2023, rating='A', bonus=9000` (perf_id=9). If a record with the same `perf_id` already exists, update the `rating` and `bonus` instead.

```sql
INSERT INTO performance
(perf_id, emp_id, year, rating, bonus)
VALUES
(9, 6, 2023, 'A', 9000)
ON DUPLICATE KEY UPDATE
rating = 'A',
bonus = 9000;
```
