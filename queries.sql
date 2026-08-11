-- =============================================================================
-- SURF-QL: ALL QUERY COMMANDS — COPY & RUN READY
-- =============================================================================
-- Load dataset.sql first, then run any section below.
-- Every query uses the shared tables:
--   employees | departments | customers | orders | products | performance
-- =============================================================================

USE surfql;

-- =============================================================================
-- SECTION 1: SELECT BASICS
-- =============================================================================

-- 1.1 Select all columns
SELECT * FROM employees;

-- 1.2 Select specific columns
SELECT emp_id, name, salary FROM employees;

-- 1.3 Column alias
SELECT name AS employee_name, salary AS annual_salary FROM employees;

-- 1.4 Expression in SELECT
SELECT name, salary, salary * 1.10 AS salary_after_hike FROM employees;

-- 1.5 Select distinct values
SELECT DISTINCT dept_id FROM employees;

-- 1.6 Select distinct on multiple columns
SELECT DISTINCT dept_id, manager_id FROM employees;

-- =============================================================================
-- SECTION 2: WHERE CLAUSE — FILTERING ROWS
-- =============================================================================

-- 2.1 Simple equality
SELECT name, salary FROM employees WHERE dept_id = 10;

-- 2.2 Greater than
SELECT name, salary FROM employees WHERE salary > 80000;

-- 2.3 AND operator
SELECT name, salary FROM employees WHERE dept_id = 10 AND salary > 80000;

-- 2.4 OR operator
SELECT name, dept_id FROM employees WHERE dept_id = 10 OR dept_id = 20;

-- 2.5 NOT operator
SELECT name, dept_id FROM employees WHERE NOT dept_id = 30;

-- 2.6 NULL check
SELECT name, dept_id FROM employees WHERE dept_id IS NULL;

-- 2.7 NOT NULL check
SELECT name, dept_id FROM employees WHERE dept_id IS NOT NULL;

-- 2.8 NULL manager (CEO)
SELECT name FROM employees WHERE manager_id IS NULL;

-- =============================================================================
-- SECTION 3: IN, BETWEEN, LIKE
-- =============================================================================

-- 3.1 IN operator
SELECT name, dept_id FROM employees WHERE dept_id IN (10, 30);

-- 3.2 NOT IN
SELECT name, dept_id FROM employees WHERE dept_id NOT IN (10, 30);

-- 3.3 BETWEEN (inclusive on both ends)
SELECT name, salary FROM employees WHERE salary BETWEEN 60000 AND 90000;

-- 3.4 NOT BETWEEN
SELECT name, salary FROM employees WHERE salary NOT BETWEEN 60000 AND 90000;

-- 3.5 LIKE — starts with
SELECT name FROM employees WHERE name LIKE 'A%';

-- 3.6 LIKE — ends with
SELECT name FROM employees WHERE name LIKE '%a';

-- 3.7 LIKE — contains
SELECT name FROM employees WHERE name LIKE '%ar%';

-- 3.8 LIKE — single character wildcard (_)
SELECT name FROM employees WHERE name LIKE '_aman%';

-- 3.9 LIKE on email domain
SELECT name, email FROM employees WHERE email LIKE '%@company.com';

-- 3.10 NOT LIKE
SELECT name FROM employees WHERE name NOT LIKE 'A%';

-- ⚠️ NOT IN NULL TRAP — if subquery could return NULL, use NOT EXISTS instead
-- This could return 0 rows if any dept_id in departments is NULL:
-- SELECT name FROM employees WHERE dept_id NOT IN (SELECT dept_id FROM departments);
-- Safe version:
SELECT name FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM departments d WHERE d.dept_id = e.dept_id
);

-- =============================================================================
-- SECTION 4: ORDER BY — SORTING
-- =============================================================================

-- 4.1 Ascending (default)
SELECT name, salary FROM employees ORDER BY salary;

-- 4.2 Descending
SELECT name, salary FROM employees ORDER BY salary DESC;

-- 4.3 Multiple columns
SELECT name, dept_id, salary FROM employees ORDER BY dept_id ASC, salary DESC;

-- 4.4 Order by alias
SELECT name, salary * 1.10 AS new_salary FROM employees ORDER BY new_salary DESC;

-- 4.5 NULLs last (MySQL default is NULLs first in ASC)
SELECT name, dept_id FROM employees ORDER BY dept_id IS NULL, dept_id;

-- =============================================================================
-- SECTION 5: LIMIT & OFFSET — PAGINATION
-- =============================================================================

-- 5.1 Top 5 earners
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 5;

-- 5.2 Page 2 (rows 6–10), page size = 5
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 5 OFFSET 5;

-- 5.3 Single highest salary
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 1;

-- 5.4 Lowest paid employee
SELECT name, salary FROM employees ORDER BY salary ASC LIMIT 1;

-- =============================================================================
-- SECTION 6: AGGREGATE FUNCTIONS
-- =============================================================================

-- 6.1 COUNT all rows
SELECT COUNT(*) AS total_employees FROM employees;

-- 6.2 COUNT non-null column
SELECT COUNT(dept_id) AS assigned_employees FROM employees;

-- 6.3 COUNT distinct values
SELECT COUNT(DISTINCT dept_id) AS num_departments FROM employees;

-- 6.4 SUM
SELECT SUM(salary) AS total_salary_bill FROM employees;

-- 6.5 AVG
SELECT AVG(salary) AS average_salary FROM employees;

-- 6.6 MIN and MAX
SELECT MIN(salary) AS lowest, MAX(salary) AS highest FROM employees;

-- 6.7 All aggregates together
SELECT
    COUNT(*)       AS total_emp,
    SUM(salary)    AS total_salary,
    AVG(salary)    AS avg_salary,
    MIN(salary)    AS min_salary,
    MAX(salary)    AS max_salary
FROM employees;

-- 6.8 Aggregates on filtered rows
SELECT AVG(salary) FROM employees WHERE dept_id = 10;

-- =============================================================================
-- SECTION 7: GROUP BY & HAVING
-- =============================================================================

-- 7.1 Count per department
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id;

-- 7.2 Avg salary per department
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;

-- 7.3 Multiple aggregates per group
SELECT
    dept_id,
    COUNT(*)          AS headcount,
    SUM(salary)       AS total_salary,
    AVG(salary)       AS avg_salary,
    MAX(salary)       AS top_salary
FROM employees
GROUP BY dept_id;

-- 7.4 HAVING — filter groups (departments with avg salary > 70000)
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > 70000;

-- 7.5 HAVING — departments with more than 2 employees
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 2;

-- 7.6 WHERE + GROUP BY + HAVING combined
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
WHERE hire_date >= '2018-01-01'   -- filter rows first
GROUP BY dept_id
HAVING AVG(salary) > 70000;       -- then filter groups

-- 7.7 Group by with ORDER BY
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id
ORDER BY headcount DESC;

-- 7.8 Orders per status
SELECT status, COUNT(*) AS order_count, SUM(amount) AS total_revenue
FROM orders
GROUP BY status;

-- =============================================================================
-- SECTION 8: CASE STATEMENT
-- =============================================================================

-- 8.1 Simple CASE — salary band
SELECT name, salary,
    CASE
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 70000 THEN 'Medium'
        ELSE 'Low'
    END AS salary_band
FROM employees;

-- 8.2 CASE in ORDER BY — custom sort priority
SELECT name, dept_id
FROM employees
ORDER BY
    CASE dept_id
        WHEN 10 THEN 1
        WHEN 20 THEN 2
        WHEN 30 THEN 3
        ELSE 4
    END;

-- 8.3 Conditional aggregation (pivot-style)
SELECT
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN status = 'pending'   THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled
FROM orders;

-- 8.4 Conditional revenue by status
SELECT
    SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS completed_revenue,
    SUM(CASE WHEN status = 'cancelled' THEN amount ELSE 0 END) AS cancelled_revenue
FROM orders;

-- =============================================================================
-- SECTION 9: JOINS
-- =============================================================================

-- 9.1 INNER JOIN — employees with their department name
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 9.2 INNER JOIN — orders with customer name and product name
SELECT o.order_id, c.name AS customer, p.product_name, o.amount, o.status
FROM orders o
JOIN customers c  ON o.customer_id = c.customer_id
JOIN products p   ON o.product_id  = p.product_id;

-- 9.3 LEFT JOIN — all employees including those without a department
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- 9.4 LEFT JOIN — all customers, including those with no orders
SELECT c.name, o.order_id, o.amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- 9.5 RIGHT JOIN — all departments, including empty ones
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 9.6 FULL OUTER JOIN (MySQL workaround using UNION)
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 9.7 SELF JOIN — employee with their manager's name
SELECT
    e.emp_id,
    e.name         AS employee,
    m.name         AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- 9.8 CROSS JOIN — all size/color type combinations (illustrative)
-- SELECT d.dept_name, p.category FROM departments d CROSS JOIN products p;

-- 9.9 ⚠️ ON vs WHERE difference in LEFT JOIN
-- Condition in ON → keeps all left rows (customers without orders get NULL)
SELECT c.name, o.order_id
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
   AND o.status = 'completed';    -- ← filters right side only

-- Condition in WHERE → drops unmatched left rows (acts like INNER JOIN!)
SELECT c.name, o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed';     -- ← removes customers with no completed order

-- 9.10 Three-table join
SELECT
    e.name        AS employee,
    d.dept_name,
    p.rating,
    p.bonus
FROM employees e
JOIN departments d  ON e.dept_id = d.dept_id
JOIN performance p  ON p.emp_id  = e.emp_id;

-- =============================================================================
-- SECTION 10: ANTI-JOIN & SEMI-JOIN
-- =============================================================================

-- 10.1 Anti-Join — customers with NO orders (LEFT JOIN + IS NULL)
SELECT c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- 10.2 Anti-Join — same using NOT EXISTS (preferred)
SELECT c.name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- 10.3 Anti-Join — employees with no performance record
SELECT e.name
FROM employees e
LEFT JOIN performance p ON e.emp_id = p.emp_id
WHERE p.emp_id IS NULL;

-- 10.4 Semi-Join — customers WHO HAVE at least one order (EXISTS)
SELECT c.name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- 10.5 Semi-Join — same using IN
SELECT name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- =============================================================================
-- SECTION 11: UNION, INTERSECT, EXCEPT
-- =============================================================================

-- 11.1 UNION — unique emails from employees and customers
SELECT email FROM employees
UNION
SELECT email FROM customers;

-- 11.2 UNION ALL — including duplicates (faster)
SELECT email FROM employees
UNION ALL
SELECT email FROM customers;

-- 11.3 INTERSECT — employees who are also in performance table (MySQL workaround)
SELECT emp_id FROM employees
WHERE emp_id IN (SELECT emp_id FROM performance);

-- 11.4 EXCEPT — employees with NO performance record (MySQL workaround)
SELECT emp_id FROM employees
WHERE emp_id NOT IN (SELECT emp_id FROM performance);

-- =============================================================================
-- SECTION 12: SUBQUERIES
-- =============================================================================

-- 12.1 Scalar subquery — employees earning above company average
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 12.2 Subquery in FROM (inline view)
SELECT dept_id, avg_sal
FROM (
    SELECT dept_id, AVG(salary) AS avg_sal
    FROM employees
    GROUP BY dept_id
) AS dept_averages
WHERE avg_sal > 70000;

-- 12.3 Subquery in HAVING
SELECT dept_id, AVG(salary) AS avg_sal
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);

-- 12.4 Correlated subquery — employees earning more than their dept average
SELECT name, dept_id, salary
FROM employees e
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE dept_id = e.dept_id
);

-- 12.5 EXISTS
SELECT name FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- 12.6 NOT EXISTS
SELECT name FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- 12.7 ANY — employees earning more than ANY finance employee
SELECT name, salary FROM employees
WHERE salary > ANY (
    SELECT salary FROM employees WHERE dept_id = 30
);

-- 12.8 ALL — employees earning more than ALL HR employees
SELECT name, salary FROM employees
WHERE salary > ALL (
    SELECT salary FROM employees WHERE dept_id = 20
);

-- =============================================================================
-- SECTION 13: CTEs (WITH CLAUSE)
-- =============================================================================

-- 13.1 Basic CTE — employees above company average salary
WITH avg_sal AS (
    SELECT AVG(salary) AS avg_salary FROM employees
)
SELECT e.name, e.salary
FROM employees e, avg_sal
WHERE e.salary > avg_sal.avg_salary;

-- 13.2 CTE for dept avg, then filter
WITH dept_avg AS (
    SELECT dept_id, AVG(salary) AS avg_sal
    FROM employees
    GROUP BY dept_id
)
SELECT e.name, e.salary, d.avg_sal
FROM employees e
JOIN dept_avg d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_sal;

-- 13.3 Multiple chained CTEs
WITH dept_avg AS (
    SELECT dept_id, AVG(salary) AS avg_sal
    FROM employees
    GROUP BY dept_id
),
dept_ranked AS (
    SELECT dept_id, avg_sal,
           RANK() OVER (ORDER BY avg_sal DESC) AS rnk
    FROM dept_avg
)
SELECT * FROM dept_ranked WHERE rnk <= 2;

-- 13.4 Recursive CTE — employee-manager hierarchy (show levels)
WITH RECURSIVE org_tree AS (
    -- Anchor: the CEO
    SELECT emp_id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: employees who report to someone in the previous level
    SELECT e.emp_id, e.name, e.manager_id, o.level + 1
    FROM employees e
    JOIN org_tree o ON e.manager_id = o.emp_id
)
SELECT level, emp_id, name FROM org_tree ORDER BY level, emp_id;

-- =============================================================================
-- SECTION 14: WINDOW FUNCTIONS
-- =============================================================================

-- 14.1 ROW_NUMBER — rank employees by salary within each department
SELECT
    emp_id, name, dept_id, salary,
    ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS row_num
FROM employees;

-- 14.2 RANK — same salary = same rank, gaps after ties
SELECT
    emp_id, name, dept_id, salary,
    RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk
FROM employees;

-- 14.3 DENSE_RANK — same salary = same rank, NO gaps
SELECT
    emp_id, name, dept_id, salary,
    DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dense_rnk
FROM employees;

-- 14.4 All three side-by-side to see the difference
SELECT
    name, dept_id, salary,
    ROW_NUMBER()  OVER (PARTITION BY dept_id ORDER BY salary DESC) AS row_num,
    RANK()        OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk,
    DENSE_RANK()  OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dense_rnk
FROM employees;

-- 14.5 NTILE(4) — divide employees into salary quartiles
SELECT name, salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS quartile
FROM employees;

-- 14.6 LAG — compare each order's amount to previous order amount
SELECT order_id, customer_id, amount, order_date,
    LAG(amount, 1) OVER (ORDER BY order_date)                         AS prev_amount,
    amount - LAG(amount, 1) OVER (ORDER BY order_date)                AS diff
FROM orders;

-- 14.7 LEAD — show next order's amount
SELECT order_id, amount, order_date,
    LEAD(amount, 1) OVER (ORDER BY order_date) AS next_amount
FROM orders;

-- 14.8 FIRST_VALUE — top salary in each department (on every row)
SELECT name, dept_id, salary,
    FIRST_VALUE(salary) OVER (
        PARTITION BY dept_id
        ORDER BY salary DESC
    ) AS top_salary_in_dept
FROM employees;

-- 14.9 Partition-level aggregates (no collapsing)
SELECT
    emp_id, name, dept_id, salary,
    AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg,
    SUM(salary) OVER (PARTITION BY dept_id) AS dept_total
FROM employees;

-- 14.10 Running total of order amounts
SELECT order_id, order_date, amount,
    SUM(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders;

-- 14.11 3-order moving average
SELECT order_id, order_date, amount,
    AVG(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3
FROM orders;

-- =============================================================================
-- SECTION 15: TOP-N PATTERNS
-- =============================================================================

-- 15.1 Top 1 salary overall
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 1;

-- 15.2 2nd highest salary — using OFFSET
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 1 OFFSET 1;

-- 15.3 Nth highest using DENSE_RANK (handles ties correctly)
WITH ranked AS (
    SELECT name, salary,
           DENSE_RANK() OVER (ORDER BY salary DESC) AS dr
    FROM employees
)
SELECT name, salary FROM ranked WHERE dr = 2;   -- change 2 to any N

-- 15.4 Top 2 salaries per department
WITH ranked AS (
    SELECT name, dept_id, salary,
           DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dr
    FROM employees
)
SELECT name, dept_id, salary FROM ranked WHERE dr <= 2;

-- 15.5 Latest order per customer
WITH latest AS (
    SELECT customer_id, order_id, order_date, amount,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
)
SELECT customer_id, order_id, order_date, amount
FROM latest WHERE rn = 1;

-- 15.6 Deduplicate — keep only the most recent performance record per employee
WITH deduped AS (
    SELECT emp_id, year, rating, bonus,
           ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY year DESC) AS rn
    FROM performance
)
SELECT emp_id, year, rating, bonus FROM deduped WHERE rn = 1;

-- =============================================================================
-- SECTION 16: INSERT, UPDATE, DELETE
-- =============================================================================

-- 16.1 Insert a single row
INSERT INTO customers (customer_id, name, city, email)
VALUES (9, 'Lakshmi Rao', 'Hyderabad', 'lakshmi.rao@gmail.com');

-- 16.2 Insert multiple rows
INSERT INTO customers (customer_id, name, city, email) VALUES
(10, 'Mohan Das',  'Kolkata', 'mohan.das@gmail.com'),
(11, 'Neeta Shah', 'Surat',   'neeta.shah@gmail.com');

-- 16.3 INSERT ... SELECT (copy high earners to archive)
-- CREATE TABLE high_earners AS SELECT emp_id, name, salary FROM employees WHERE 1=0;
-- INSERT INTO high_earners SELECT emp_id, name, salary FROM employees WHERE salary > 90000;

-- 16.4 Update a single employee's salary
UPDATE employees SET salary = 90000 WHERE emp_id = 2;

-- 16.5 Update multiple columns
UPDATE employees SET salary = 95000, email = 'aman.s@company.com' WHERE emp_id = 2;

-- 16.6 Update based on a subquery — give A-rated employees a 10% raise
UPDATE employees
SET salary = salary * 1.10
WHERE emp_id IN (
    SELECT emp_id FROM performance WHERE rating = 'A'
);

-- 16.7 ⚠️ Bulk update (dangerous without WHERE) — just for awareness:
-- UPDATE employees SET salary = salary * 1.05;  -- affects ALL rows!

-- 16.8 Delete a specific row
DELETE FROM customers WHERE customer_id = 11;

-- 16.9 Delete based on subquery — remove cancelled orders older than 2024
DELETE FROM orders
WHERE status = 'cancelled' AND order_date < '2024-01-01';

-- 16.10 TRUNCATE — remove all rows, keep table structure
-- TRUNCATE TABLE high_earners;

-- =============================================================================
-- SECTION 17: DDL — CREATE, ALTER, DROP
-- =============================================================================

-- 17.1 Create a new table
CREATE TABLE IF NOT EXISTS salary_archive (
    archive_id  INT PRIMARY KEY AUTO_INCREMENT,
    emp_id      INT,
    old_salary  DECIMAL(10,2),
    new_salary  DECIMAL(10,2),
    changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 17.2 Add a column
ALTER TABLE employees ADD COLUMN phone VARCHAR(20);

-- 17.3 Drop a column
ALTER TABLE employees DROP COLUMN phone;

-- 17.4 Rename a column (MySQL 8.0+)
-- ALTER TABLE employees RENAME COLUMN email TO work_email;

-- 17.5 Add a constraint
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary > 0);

-- 17.6 Drop a constraint (MySQL)
-- ALTER TABLE employees DROP CHECK chk_salary;

-- 17.7 Create a view — employees with department name
CREATE OR REPLACE VIEW v_emp_dept AS
SELECT e.emp_id, e.name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- Use the view
SELECT * FROM v_emp_dept;

-- 17.8 Drop the view
DROP VIEW IF EXISTS v_emp_dept;

-- 17.9 Create an index on salary
CREATE INDEX idx_emp_salary ON employees(salary);

-- 17.10 Composite index
CREATE INDEX idx_emp_dept_salary ON employees(dept_id, salary);

-- 17.11 Drop index
DROP INDEX idx_emp_salary ON employees;

-- =============================================================================
-- SECTION 18: TRANSACTIONS
-- =============================================================================

-- 18.1 Basic transaction — transfer style (illustrative)
START TRANSACTION;
    UPDATE employees SET salary = salary - 5000 WHERE emp_id = 2;
    UPDATE employees SET salary = salary + 5000 WHERE emp_id = 6;
COMMIT;

-- 18.2 ROLLBACK — undo if something goes wrong
START TRANSACTION;
    UPDATE employees SET salary = 0 WHERE dept_id = 10;  -- oops
ROLLBACK;  -- undone

-- 18.3 SAVEPOINT — partial rollback
START TRANSACTION;
    UPDATE employees SET salary = salary + 2000 WHERE emp_id = 2;
    SAVEPOINT sp_after_aman;
    UPDATE employees SET salary = salary + 2000 WHERE emp_id = 6;
ROLLBACK TO sp_after_aman;  -- undo Dev's raise only
COMMIT;                     -- keep Aman's raise

-- =============================================================================
-- SECTION 19: STRING FUNCTIONS
-- =============================================================================

-- 19.1 CONCAT
SELECT CONCAT(name, ' — ', email) AS full_info FROM employees;

-- 19.2 UPPER / LOWER
SELECT UPPER(name), LOWER(email) FROM employees;

-- 19.3 LENGTH
SELECT name, LENGTH(name) AS name_length FROM employees ORDER BY name_length;

-- 19.4 SUBSTRING — first 4 chars of name
SELECT name, SUBSTRING(name, 1, 4) AS short_name FROM employees;

-- 19.5 LEFT / RIGHT
SELECT name, LEFT(name, 5) AS first5, RIGHT(name, 5) AS last5 FROM employees;

-- 19.6 TRIM
SELECT TRIM('  hello world  ') AS trimmed;

-- 19.7 REPLACE — mask email domain
SELECT REPLACE(email, '@company.com', '@[hidden]') AS masked FROM employees;

-- 19.8 INSTR — position of @ in email
SELECT email, INSTR(email, '@') AS at_position FROM employees;

-- 19.9 Extract domain from email
SELECT email, SUBSTRING(email, INSTR(email, '@') + 1) AS domain FROM employees;

-- 19.10 COALESCE — replace NULL with a default
SELECT name, COALESCE(dept_id, -1) AS dept_id FROM employees;

-- 19.11 NULLIF — return NULL if value equals a specific value
SELECT name, NULLIF(dept_id, 10) AS dept_if_not_eng FROM employees;

-- =============================================================================
-- SECTION 20: DATE FUNCTIONS
-- =============================================================================

-- 20.1 Current date and time
SELECT CURRENT_DATE, NOW();

-- 20.2 Employee tenure in days
SELECT name, hire_date, DATEDIFF(CURRENT_DATE, hire_date) AS days_worked
FROM employees;

-- 20.3 Employee tenure in years
SELECT name, hire_date,
       TIMESTAMPDIFF(YEAR, hire_date, CURRENT_DATE) AS years_of_service
FROM employees;

-- 20.4 Employees hired in the last 2 years
SELECT name, hire_date
FROM employees
WHERE hire_date >= DATE_SUB(CURRENT_DATE, INTERVAL 2 YEAR);

-- 20.5 Employees hired in 2020
SELECT name, hire_date
FROM employees
WHERE YEAR(hire_date) = 2020;

-- 20.6 Orders per month
SELECT
    YEAR(order_date)  AS yr,
    MONTH(order_date) AS mo,
    COUNT(*)          AS total_orders,
    SUM(amount)       AS revenue
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY yr, mo;

-- 20.7 Orders in Q1 2024
SELECT order_id, order_date, amount
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- 20.8 Add 30 days to order date
SELECT order_id, order_date,
       DATE_ADD(order_date, INTERVAL 30 DAY) AS expected_delivery
FROM orders;

-- 20.9 Format date output
SELECT order_id, DATE_FORMAT(order_date, '%d %b %Y') AS formatted_date
FROM orders;

-- =============================================================================
-- SECTION 21: INTERVIEW CLASSICS
-- =============================================================================

-- 21.1 Employees earning above company average
SELECT name, salary FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 21.2 Department with the highest average salary
SELECT dept_id, AVG(salary) AS avg_sal
FROM employees
GROUP BY dept_id
ORDER BY avg_sal DESC
LIMIT 1;

-- 21.3 Departments with average salary above the company average
WITH company_avg AS (SELECT AVG(salary) AS avg_sal FROM employees)
SELECT e.dept_id, AVG(e.salary) AS dept_avg
FROM employees e, company_avg
GROUP BY e.dept_id
HAVING AVG(e.salary) > company_avg.avg_sal;

-- 21.4 Employees who have NEVER received a performance rating
SELECT e.name
FROM employees e
LEFT JOIN performance p ON e.emp_id = p.emp_id
WHERE p.emp_id IS NULL;

-- 21.5 Top earner in each department
WITH ranked AS (
    SELECT name, dept_id, salary,
           ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT name, dept_id, salary FROM ranked WHERE rn = 1;

-- 21.6 Customers with more than 1 order
SELECT customer_id, COUNT(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 21.7 Revenue by product category
SELECT p.category, SUM(o.amount) AS total_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 21.8 Most purchased product
SELECT p.product_name, COUNT(*) AS times_ordered
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY times_ordered DESC
LIMIT 1;

-- 21.9 Employees with same salary as another employee
SELECT DISTINCT e1.name, e1.salary
FROM employees e1
JOIN employees e2
  ON e1.salary = e2.salary AND e1.emp_id != e2.emp_id;

-- 21.10 Running revenue total by order date
SELECT order_date, amount,
    SUM(amount) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM orders;

-- 21.11 Departments with NO employees
SELECT d.dept_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;

-- 21.12 Second highest salary (DENSE_RANK — correct for ties)
WITH ranked AS (
    SELECT name, salary,
           DENSE_RANK() OVER (ORDER BY salary DESC) AS dr
    FROM employees
)
SELECT name, salary FROM ranked WHERE dr = 2;

-- 21.13 Month-over-month revenue change
WITH monthly AS (
    SELECT
        YEAR(order_date)  AS yr,
        MONTH(order_date) AS mo,
        SUM(amount)       AS revenue
    FROM orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT yr, mo, revenue,
    LAG(revenue) OVER (ORDER BY yr, mo)            AS prev_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY yr, mo)  AS change
FROM monthly;

-- 21.14 Employee with highest bonus total
SELECT e.name, SUM(p.bonus) AS total_bonus
FROM employees e
JOIN performance p ON e.emp_id = p.emp_id
GROUP BY e.emp_id, e.name
ORDER BY total_bonus DESC
LIMIT 1;

-- 21.15 Employees whose salary is in the top 25% (NTILE)
WITH quartiles AS (
    SELECT name, salary,
           NTILE(4) OVER (ORDER BY salary DESC) AS q
    FROM employees
)
SELECT name, salary FROM quartiles WHERE q = 1;

-- =============================================================================
-- END OF FILE
-- Load dataset.sql → run any query above → practice!
-- =============================================================================
