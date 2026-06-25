# SQL Commands for Interviews (Comprehensive + Priority Wise)

This file is a placement-focused command bank.
It covers the most asked SQL commands across common databases (MySQL, PostgreSQL, SQL Server, Oracle).

## Priority Legend

- IMPORTANT: Asked very frequently in interviews; must master.
- MEDIUM: Asked often in interviews and coding rounds.
- ADVANCED: Less frequent, but strong for higher-level rounds.

## IMPORTANT Commands (Must Know)

### SELECT

Purpose: Fetch data from one or more tables.

```sql
SELECT emp_id, name, salary
FROM employees;
```

### SELECT DISTINCT

Purpose: Remove duplicate rows in result.

```sql
SELECT DISTINCT dept
FROM employees;
```

### WHERE + AND/OR/NOT

Purpose: Filter rows.

```sql
SELECT *
FROM employees
WHERE dept = 'Engineering' AND salary > 60000;
```

### IN, BETWEEN, LIKE, IS NULL

Purpose: Common interview filters.

```sql
SELECT * FROM employees WHERE dept IN ('Engineering', 'HR');
SELECT * FROM employees WHERE salary BETWEEN 50000 AND 90000;
SELECT * FROM employees WHERE name LIKE 'A%';
SELECT * FROM employees WHERE manager_id IS NULL;
```

### ORDER BY + LIMIT/OFFSET

Purpose: Sorting and pagination.

```sql
SELECT name, salary
FROM employees
ORDER BY salary DESC
LIMIT 5 OFFSET 0;
```

### GROUP BY + HAVING

Purpose: Aggregate grouped data.

```sql
SELECT dept, COUNT(*) AS total, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept
HAVING AVG(salary) > 60000;
```

### Aggregate Functions

Purpose: Basic analytics.

```sql
SELECT
  COUNT(*) AS total_rows,
  SUM(salary) AS total_salary,
  AVG(salary) AS avg_salary,
  MIN(salary) AS min_salary,
  MAX(salary) AS max_salary
FROM employees;
```

### JOIN (INNER, LEFT, RIGHT, FULL)

Purpose: Combine related tables.

```sql
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
```

### INSERT

Purpose: Add rows.

```sql
INSERT INTO employees (emp_id, name, dept_id, salary)
VALUES (101, 'Aman', 10, 65000);
```

### UPDATE

Purpose: Modify existing rows.

```sql
UPDATE employees
SET salary = salary + 5000
WHERE emp_id = 101;
```

### DELETE

Purpose: Remove rows.

```sql
DELETE FROM employees
WHERE emp_id = 101;
```

### CREATE TABLE

Purpose: Create table structure.

```sql
CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  dept_id INT,
  salary DECIMAL(10,2),
  join_date DATE
);
```

### ALTER TABLE

Purpose: Modify table schema.

```sql
ALTER TABLE employees ADD email VARCHAR(120);
ALTER TABLE employees DROP COLUMN email;
```

### DROP vs TRUNCATE

Purpose: Remove data or structure.

```sql
TRUNCATE TABLE employees; -- removes all rows, keeps table
DROP TABLE employees;     -- removes table itself
```

### Constraints

Purpose: Enforce data integrity.

```sql
CREATE TABLE students (
  id INT PRIMARY KEY,
  email VARCHAR(120) UNIQUE,
  age INT CHECK (age >= 18),
  course_id INT,
  FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
```

### Transactions: BEGIN/COMMIT/ROLLBACK

Purpose: Atomic multi-step updates.

```sql
BEGIN;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 2;
COMMIT;
-- ROLLBACK; if something fails before commit
```

### Subquery

Purpose: Nested query logic.

```sql
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

### CTE (WITH)

Purpose: Improve readability and break complex query logic.

```sql
WITH dept_avg AS (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
)
SELECT e.name, e.salary
FROM employees e
JOIN dept_avg d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_salary;
```

### Window Functions (ROW_NUMBER, RANK, DENSE_RANK)

Purpose: Ranking and analytics without collapsing rows.

```sql
SELECT
  name,
  dept_id,
  salary,
  ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn,
  RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk,
  DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS drnk
FROM employees;
```

## MEDIUM Commands (Strong Interview Edge)

### CASE WHEN

Purpose: Conditional output inside queries.

```sql
SELECT name,
       CASE
         WHEN salary >= 100000 THEN 'High'
         WHEN salary >= 60000 THEN 'Medium'
         ELSE 'Low'
       END AS salary_band
FROM employees;
```

### EXISTS / NOT EXISTS

Purpose: Correlated checks.

```sql
SELECT c.customer_id
FROM customers c
WHERE EXISTS (
  SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
```

### ANY / ALL

Purpose: Compare against subquery set.

```sql
SELECT name, salary
FROM employees
WHERE salary > ALL (SELECT salary FROM employees WHERE dept_id = 20);
```

### UNION / UNION ALL

Purpose: Combine row sets.

```sql
SELECT email FROM customers
UNION
SELECT email FROM leads;

SELECT email FROM customers
UNION ALL
SELECT email FROM leads;
```

### INTERSECT / EXCEPT

Purpose: Set intersection and difference.

```sql
SELECT emp_id FROM active_employees
INTERSECT
SELECT emp_id FROM training_completed;

SELECT emp_id FROM all_employees
EXCEPT
SELECT emp_id FROM resigned_employees;
```

### INSERT ... SELECT

Purpose: Copy transformed data.

```sql
INSERT INTO high_earners (emp_id, name, salary)
SELECT emp_id, name, salary
FROM employees
WHERE salary > 90000;
```

### UPDATE with JOIN (dialect dependent)

Purpose: Update based on another table.

```sql
UPDATE employees e
SET salary = salary * 1.10
FROM increments i
WHERE e.emp_id = i.emp_id;
```

### DELETE with JOIN/Subquery

Purpose: Conditional cleanup.

```sql
DELETE FROM employees
WHERE dept_id IN (
  SELECT dept_id FROM departments WHERE status = 'closed'
);
```

### CREATE VIEW / DROP VIEW

Purpose: Save reusable query as virtual table.

```sql
CREATE VIEW v_engineering AS
SELECT emp_id, name, salary
FROM employees
WHERE dept_id = 10;

DROP VIEW v_engineering;
```

### CREATE INDEX / DROP INDEX

Purpose: Speed up reads.

```sql
CREATE INDEX idx_emp_dept_salary
ON employees (dept_id, salary);

DROP INDEX idx_emp_dept_salary;
```

### EXPLAIN (or EXPLAIN ANALYZE)

Purpose: Inspect query plan for optimization.

```sql
EXPLAIN
SELECT * FROM employees WHERE dept_id = 10 AND salary > 70000;
```

### SAVEPOINT

Purpose: Partial rollback point inside transaction.

```sql
BEGIN;
UPDATE accounts SET balance = balance - 2000 WHERE account_id = 1;
SAVEPOINT sp1;
UPDATE accounts SET balance = balance + 2000 WHERE account_id = 2;
ROLLBACK TO sp1;
COMMIT;
```

### GRANT / REVOKE

Purpose: Permissions and access control.

```sql
GRANT SELECT, INSERT ON employees TO analyst_user;
REVOKE INSERT ON employees FROM analyst_user;
```

## ADVANCED Commands (Good for Experienced Rounds)

### MERGE (SQL Server/Oracle/PostgreSQL 15+)

Purpose: Upsert in one statement.

```sql
MERGE INTO employees e
USING staging_employees s
ON (e.emp_id = s.emp_id)
WHEN MATCHED THEN
  UPDATE SET salary = s.salary
WHEN NOT MATCHED THEN
  INSERT (emp_id, name, salary)
  VALUES (s.emp_id, s.name, s.salary);
```

### UPSERT (PostgreSQL/MySQL styles)

Purpose: Insert or update on conflict.

```sql
-- PostgreSQL
INSERT INTO employees (emp_id, name, salary)
VALUES (101, 'Aman', 70000)
ON CONFLICT (emp_id)
DO UPDATE SET salary = EXCLUDED.salary;

-- MySQL
INSERT INTO employees (emp_id, name, salary)
VALUES (101, 'Aman', 70000)
ON DUPLICATE KEY UPDATE salary = VALUES(salary);
```

### Recursive CTE

Purpose: Hierarchical data traversal.

```sql
WITH RECURSIVE org AS (
  SELECT emp_id, manager_id, name, 1 AS lvl
  FROM employees
  WHERE manager_id IS NULL

  UNION ALL

  SELECT e.emp_id, e.manager_id, e.name, o.lvl + 1
  FROM employees e
  JOIN org o ON e.manager_id = o.emp_id
)
SELECT * FROM org;
```

### Stored Procedure (dialect dependent)

Purpose: Encapsulate reusable server-side logic.

```sql
CREATE PROCEDURE give_bonus()
LANGUAGE SQL
AS $$
  UPDATE employees SET salary = salary * 1.05 WHERE dept_id = 10;
$$;
```

### Trigger

Purpose: Auto-run logic on data change events.

```sql
CREATE TRIGGER trg_after_insert
AFTER INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION audit_employee_insert();
```

### Materialized View (where supported)

Purpose: Persisted query result for faster reads.

```sql
CREATE MATERIALIZED VIEW mv_dept_summary AS
SELECT dept_id, COUNT(*) AS cnt, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;
```

## Interview Rapid-Fire Differences (Very Common)

- DELETE vs TRUNCATE vs DROP
- WHERE vs HAVING
- INNER JOIN vs LEFT JOIN
- UNION vs UNION ALL
- RANK vs DENSE_RANK vs ROW_NUMBER
- PRIMARY KEY vs UNIQUE KEY
- EXISTS vs IN
- CTE vs Subquery
- COMMIT vs ROLLBACK

## Dialect Notes

- LIMIT is MySQL/PostgreSQL; SQL Server uses TOP/FETCH.
- FULL OUTER JOIN is not supported directly in older MySQL versions.
- MERGE support depends on database version.
- CHECK constraints and trigger syntax differ by vendor.

## Suggested Preparation Order

1. IMPORTANT commands.
2. MEDIUM commands.
3. ADVANCED commands based on target company level.
