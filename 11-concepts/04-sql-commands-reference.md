# SQL Commands Reference — The Complete Cheatsheet

> **Interview Priority**: 🔴 Quick-Reference Before Any Interview

A comprehensive reference card for all SQL commands, functions, and syntax. Use this for last-minute review.

---

## DDL — Data Definition Language (Structure)

```sql
-- CREATE TABLE
CREATE TABLE employees (
  emp_id    INT           PRIMARY KEY,
  name      VARCHAR(100)  NOT NULL,
  dept_id   INT,
  manager_id INT,
  salary    DECIMAL(10,2) DEFAULT 0,
  hire_date DATE,
  email     VARCHAR(120)  UNIQUE,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- CREATE TABLE AS (copy structure + data)
CREATE TABLE emp_backup AS SELECT * FROM employees;

-- ALTER TABLE
ALTER TABLE employees ADD COLUMN phone VARCHAR(20);
ALTER TABLE employees DROP COLUMN phone;
ALTER TABLE employees RENAME COLUMN name TO full_name;       -- PostgreSQL
ALTER TABLE employees MODIFY COLUMN salary DECIMAL(12,2);    -- MySQL
ALTER TABLE employees ALTER COLUMN salary TYPE DECIMAL(12,2); -- PostgreSQL
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary >= 0);
ALTER TABLE employees DROP CONSTRAINT chk_salary;

-- DROP & TRUNCATE
DROP TABLE employees;                  -- removes table + data permanently
DROP TABLE IF EXISTS employees;        -- safe version
TRUNCATE TABLE employees;              -- removes all rows, keeps table
DROP DATABASE my_database;
CREATE DATABASE IF NOT EXISTS my_database;
```

---

## DML — Data Manipulation Language (Rows)

```sql
-- INSERT
INSERT INTO employees (emp_id, name, dept_id, salary)
VALUES (1, 'Aman', 10, 85000);

-- Insert multiple rows
INSERT INTO employees (emp_id, name, dept_id, salary) VALUES
  (2, 'Priya', 20, 62000),
  (3, 'Ravi',  30, 91000);

-- INSERT ... SELECT (copy from another table)
INSERT INTO high_earners (emp_id, name, salary)
SELECT emp_id, name, salary FROM employees WHERE salary > 90000;

-- UPDATE
UPDATE employees SET salary = salary * 1.10 WHERE dept_id = 10;
UPDATE employees SET salary = 70000, email = 'new@co.com' WHERE emp_id = 5;

-- UPDATE with subquery
UPDATE employees
SET salary = salary * 1.05
WHERE emp_id IN (SELECT emp_id FROM performance WHERE rating = 'A');

-- DELETE
DELETE FROM employees WHERE emp_id = 101;
DELETE FROM orders WHERE status = 'cancelled' AND order_date < '2023-01-01';

-- DELETE with subquery
DELETE FROM employees
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'Closed');
```

---

## DQL — Data Query Language (SELECT)

```sql
-- Full SELECT clause order
SELECT DISTINCT
  e.emp_id,
  e.name,
  d.dept_name,
  e.salary,
  CASE WHEN e.salary > 90000 THEN 'High' ELSE 'Normal' END AS band
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
  AND e.hire_date >= '2020-01-01'
GROUP BY e.emp_id, e.name, d.dept_name, e.salary
HAVING AVG(e.salary) > 60000
ORDER BY e.salary DESC
LIMIT 10 OFFSET 0;

-- Subquery
SELECT name FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- CTE
WITH dept_avg AS (
  SELECT dept_id, AVG(salary) AS avg_sal
  FROM employees GROUP BY dept_id
)
SELECT e.name, e.salary, d.avg_sal
FROM employees e JOIN dept_avg d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_sal;

-- EXISTS
SELECT name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- UNION / INTERSECT / EXCEPT
SELECT email FROM customers UNION SELECT email FROM employees;
SELECT email FROM customers UNION ALL SELECT email FROM employees;
SELECT emp_id FROM employees INTERSECT SELECT emp_id FROM performance;
SELECT emp_id FROM employees EXCEPT SELECT emp_id FROM performance;
```

---

## TCL — Transaction Control Language

```sql
BEGIN;                                          -- start transaction
UPDATE accounts SET balance = balance - 500 WHERE id = 1;
SAVEPOINT sp1;
UPDATE accounts SET balance = balance + 500 WHERE id = 2;
ROLLBACK TO sp1;                                -- undo back to savepoint
COMMIT;                                         -- persist all changes
ROLLBACK;                                       -- undo everything since BEGIN
```

---

## DCL — Data Control Language (Permissions)

```sql
GRANT SELECT, INSERT, UPDATE ON employees TO analyst_user;
GRANT ALL PRIVILEGES ON employees TO admin_user;
REVOKE INSERT ON employees FROM analyst_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;  -- PostgreSQL
```

---

## Window Functions Quick Reference

```sql
-- Syntax
FUNCTION() OVER (
  [PARTITION BY col]
  [ORDER BY col]
  [ROWS BETWEEN ... AND ...]
)

-- Ranking functions
ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC)   -- unique 1,2,3
RANK()       OVER (PARTITION BY dept_id ORDER BY salary DESC)   -- ties share rank, gaps: 1,1,3
DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC)   -- ties share rank, no gaps: 1,1,2
NTILE(4)     OVER (ORDER BY salary DESC)                        -- quartiles

-- Value functions
LAG(salary, 1)              OVER (ORDER BY hire_date)   -- previous row
LEAD(salary, 1)             OVER (ORDER BY hire_date)   -- next row
FIRST_VALUE(salary)         OVER (PARTITION BY dept_id ORDER BY salary DESC)
LAST_VALUE(salary)          OVER (PARTITION BY dept_id ORDER BY salary DESC
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)

-- Aggregate window functions
SUM(amount)   OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
AVG(salary)   OVER (PARTITION BY dept_id)
COUNT(emp_id) OVER (PARTITION BY dept_id)

-- Top N per group pattern
WITH ranked AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dr
  FROM employees
)
SELECT * FROM ranked WHERE dr <= 3;
```

---

## Aggregate Functions Quick Reference

```sql
COUNT(*)                    -- all rows including NULLs
COUNT(salary)               -- non-NULL salary rows only
COUNT(DISTINCT dept_id)     -- unique non-NULL dept values
SUM(salary)                 -- total (ignores NULLs)
AVG(salary)                 -- average (ignores NULLs — trap: denominator excludes NULLs)
MIN(salary)                 -- smallest non-NULL value
MAX(salary)                 -- largest non-NULL value
GROUP_CONCAT(name)          -- MySQL: concatenate values in group
STRING_AGG(name, ', ')      -- PostgreSQL equivalent
```

---

## String Functions Quick Reference

```sql
CONCAT(first_name, ' ', last_name)             -- join strings
CONCAT_WS(' ', first_name, last_name)          -- join with separator (skips NULLs)
LENGTH(name)                                   -- byte length
CHAR_LENGTH(name)                              -- character length (use this for Unicode)
UPPER(name)          LOWER(name)               -- case change
TRIM(name)           LTRIM(name)  RTRIM(name) -- remove whitespace
SUBSTRING(email, 1, 5)                         -- extract chars (1-indexed)
LEFT(name, 3)        RIGHT(name, 3)            -- first/last N chars
REPLACE(email, '@old.com', '@new.com')         -- find and replace
INSTR(email, '@')                              -- MySQL: position of substring
POSITION('@' IN email)                         -- SQL standard
LPAD(emp_id::text, 5, '0')                    -- left pad: 00042
COALESCE(manager_id, 0)                        -- return first non-NULL
NULLIF(salary, 0)                              -- return NULL if salary = 0
```

---

## Date Functions Quick Reference

```sql
CURRENT_DATE                                    -- today's date
NOW()                                           -- current date + time
CURDATE()                                       -- MySQL alias for CURRENT_DATE

-- Add / subtract
DATE_ADD(hire_date, INTERVAL 90 DAY)           -- MySQL
hire_date + INTERVAL '90 days'                 -- PostgreSQL
DATEADD(DAY, 90, hire_date)                    -- SQL Server

-- Difference
DATEDIFF(NOW(), hire_date)                     -- MySQL: days between
DATE_PART('year', AGE(hire_date))              -- PostgreSQL: years difference
TIMESTAMPDIFF(YEAR, hire_date, NOW())          -- MySQL: difference in years

-- Extract parts
YEAR(hire_date)   MONTH(hire_date)   DAY(hire_date)   -- MySQL
EXTRACT(YEAR FROM hire_date)                           -- SQL standard

-- Format output
DATE_FORMAT(order_date, '%Y-%m')               -- MySQL: 2024-01
TO_CHAR(order_date, 'YYYY-MM')                 -- PostgreSQL
DATE_TRUNC('month', order_date)                -- PostgreSQL: truncate to month start
```

---

## Constraints Quick Reference

| Constraint | Meaning | NULL allowed? | Multiple per table? |
|---|---|---|---|
| `PRIMARY KEY` | Unique identifier, not null | ❌ No | ❌ One only |
| `UNIQUE` | No duplicates | ✅ Yes (one NULL) | ✅ Yes |
| `NOT NULL` | Cannot be NULL | — | ✅ Yes |
| `FOREIGN KEY` | References PK in another table | ✅ Yes | ✅ Yes |
| `CHECK` | Custom validation condition | — | ✅ Yes |
| `DEFAULT` | Value when none provided | — | ✅ Yes |

---

## SQL Command Categories

| Category | Commands | Purpose |
|---|---|---|
| **DDL** | CREATE, ALTER, DROP, TRUNCATE | Modify database structure |
| **DML** | INSERT, UPDATE, DELETE | Modify data |
| **DQL** | SELECT | Query data |
| **TCL** | BEGIN, COMMIT, ROLLBACK, SAVEPOINT | Transaction control |
| **DCL** | GRANT, REVOKE | Access control |

---

## Execution Order (Logical)

```
1. FROM / JOIN      — identify source tables
2. WHERE            — filter rows
3. GROUP BY         — form groups
4. HAVING           — filter groups
5. SELECT           — compute output columns
6. DISTINCT         — remove duplicates
7. ORDER BY         — sort results
8. LIMIT / OFFSET   — paginate
```

> Window functions execute at step 5 (SELECT), after WHERE/GROUP BY, so they can't be in WHERE.
