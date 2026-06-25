# Top SQL Interview Patterns — The Master Quick Reference

> **Interview Priority**: 🔴 Must Know

## What Is It?

These 12 patterns cover the overwhelming majority of SQL interview problems. Rather than memorizing individual questions, recognizing which **pattern** applies lets you solve any variation quickly. This file is a quick-reference — one template + one concrete example per pattern.

---

## Pattern 1: Aggregation + GROUP BY

**What it solves**: "How many / how much / what is the total ___ per ___?"

```sql
-- Template
SELECT grouping_column, AGG_FUNCTION(measure_column)
FROM table
GROUP BY grouping_column;
```

```sql
-- Example: Total salary expense per department
SELECT d.dept_name,
       COUNT(e.emp_id)   AS headcount,
       SUM(e.salary)     AS total_salary,
       AVG(e.salary)     AS avg_salary,
       MAX(e.salary)     AS max_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY total_salary DESC;
```

---

## Pattern 2: Filtering After Aggregation (HAVING)

**What it solves**: Filter groups based on an aggregate value (can't use WHERE for this).

```sql
-- Template
SELECT grouping_column, AGG_FUNCTION(col)
FROM table
GROUP BY grouping_column
HAVING AGG_FUNCTION(col) [condition];
```

```sql
-- Example: Departments with more than 2 employees AND avg salary > 70000
SELECT d.dept_name,
       COUNT(e.emp_id)   AS headcount,
       AVG(e.salary)     AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING COUNT(e.emp_id) > 2
   AND AVG(e.salary) > 70000;
```

> **Key rule**: `WHERE` filters rows before grouping. `HAVING` filters groups after aggregation. You cannot use aggregate functions in `WHERE`.

---

## Pattern 3: Top-N Per Group (PARTITION BY + ROW_NUMBER / DENSE_RANK)

**What it solves**: "Find the top 3 highest-paid employees in each department."

```sql
-- Template
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY group_col ORDER BY measure_col DESC) AS rn
    FROM table
)
SELECT * FROM ranked WHERE rn <= N;
```

```sql
-- Example: Top 2 highest-paid employees per department
WITH ranked AS (
    SELECT e.name, e.dept_id, e.salary, d.dept_name,
           DENSE_RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS rnk
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
)
SELECT dept_name, name, salary, rnk
FROM ranked
WHERE rnk <= 2
ORDER BY dept_name, rnk;
```

> **DENSE_RANK vs ROW_NUMBER**: Use `DENSE_RANK` when ties should share a rank (both employees with the same salary get rank 1). Use `ROW_NUMBER` when you need exactly N rows, no ties.

---

## Pattern 4: Anti-Join (NOT EXISTS / LEFT JOIN IS NULL)

**What it solves**: "Find records in table A that have NO match in table B."

```sql
-- Template (two approaches — same result)
-- Approach A: LEFT JOIN IS NULL
SELECT a.*
FROM table_a a
LEFT JOIN table_b b ON a.id = b.a_id
WHERE b.a_id IS NULL;

-- Approach B: NOT EXISTS
SELECT a.*
FROM table_a a
WHERE NOT EXISTS (
    SELECT 1 FROM table_b b WHERE b.a_id = a.id
);
```

```sql
-- Example: Customers who have never placed an order
SELECT c.customer_id, c.name, c.city
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- Same result with NOT EXISTS
SELECT c.customer_id, c.name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
```

> **Prefer NOT EXISTS over NOT IN** when the subquery can return NULLs — `NOT IN` with a NULL in the subquery returns an empty result set (the NULL trap).

---

## Pattern 5: Semi-Join (EXISTS / IN)

**What it solves**: "Find records in table A where a matching record exists in table B" — without duplicating rows from A.

```sql
-- Template
SELECT a.*
FROM table_a a
WHERE EXISTS (
    SELECT 1 FROM table_b b WHERE b.a_id = a.id
);
```

```sql
-- Example: Customers who have placed at least one order with amount > 5000
SELECT c.customer_id, c.name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.amount > 5000
);

-- IN approach (equivalent for small subqueries without NULLs)
SELECT name FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE amount > 5000
);
```

---

## Pattern 6: Running Total (SUM OVER)

**What it solves**: Cumulative sum — each row shows the total up to that point.

```sql
-- Template
SELECT col,
       SUM(measure) OVER (ORDER BY col) AS running_total
FROM table;
```

```sql
-- Example: Running total of order amounts over time
SELECT order_id,
       order_date,
       amount,
       SUM(amount) OVER (ORDER BY order_date, order_id) AS running_total
FROM orders
ORDER BY order_date, order_id;

-- Running total per customer
SELECT customer_id, order_date, amount,
       SUM(amount) OVER (
           PARTITION BY customer_id
           ORDER BY order_date, order_id
       ) AS customer_running_total
FROM orders;
```

---

## Pattern 7: Day-Over-Day / Period Comparison (LAG)

**What it solves**: Compare each row's value to the previous row's value.

```sql
-- Template
SELECT col, measure,
       LAG(measure) OVER (ORDER BY col) AS prev_value,
       measure - LAG(measure) OVER (ORDER BY col) AS change
FROM table;
```

```sql
-- Example: Month-over-month revenue change
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(amount) AS revenue,
    LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS prev_month,
    SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS mom_change
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
```

> `LEAD()` looks at the *next* row. `LAG()` looks at the *previous* row. Both accept an optional offset (default 1) and a default value for when there's no previous/next row.

---

## Pattern 8: Deduplication (ROW_NUMBER)

**What it solves**: Keep only one row per group when there are duplicates.

```sql
-- Template
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY duplicate_key ORDER BY tiebreak_col DESC) AS rn
    FROM table
)
SELECT * FROM deduped WHERE rn = 1;
```

```sql
-- Example: Keep only the most recent performance record per employee
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY year DESC) AS rn
    FROM performance
)
SELECT emp_id, year, rating, bonus
FROM deduped
WHERE rn = 1;

-- Example: Find duplicate emails in employees
WITH ranked AS (
    SELECT name, email,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY emp_id) AS rn
    FROM employees
)
SELECT name, email FROM ranked WHERE rn > 1;  -- shows the duplicates
```

---

## Pattern 9: Conditional Aggregation (SUM CASE WHEN)

**What it solves**: Pivot-style aggregation — aggregate only rows meeting a condition.

```sql
-- Template
SELECT grouping_col,
       SUM(CASE WHEN condition THEN measure ELSE 0 END) AS conditional_sum,
       COUNT(CASE WHEN condition THEN 1 END)            AS conditional_count
FROM table
GROUP BY grouping_col;
```

```sql
-- Example: Revenue by order status, side by side
SELECT
    YEAR(order_date) AS yr,
    SUM(CASE WHEN status = 'Completed' THEN amount ELSE 0 END) AS completed_revenue,
    SUM(CASE WHEN status = 'Pending'   THEN amount ELSE 0 END) AS pending_revenue,
    SUM(CASE WHEN status = 'Cancelled' THEN amount ELSE 0 END) AS cancelled_revenue,
    COUNT(CASE WHEN status = 'Completed' THEN 1 END)           AS completed_count
FROM orders
GROUP BY YEAR(order_date)
ORDER BY yr;

-- Example: Employee count per rating per year from performance table
SELECT year,
       COUNT(CASE WHEN rating = 'A' THEN 1 END) AS grade_A,
       COUNT(CASE WHEN rating = 'B' THEN 1 END) AS grade_B,
       COUNT(CASE WHEN rating = 'C' THEN 1 END) AS grade_C
FROM performance
GROUP BY year
ORDER BY year;
```

---

## Pattern 10: Multi-Table Join

**What it solves**: Bring together data from multiple related tables.

```sql
-- Template
SELECT a.col1, b.col2, c.col3
FROM table_a a
JOIN table_b b ON a.fk = b.pk
JOIN table_c c ON b.fk2 = c.pk
WHERE [conditions];
```

```sql
-- Example: Full order details — customer, product, amount
SELECT
    c.name              AS customer_name,
    c.city,
    p.product_name,
    p.category,
    o.amount,
    o.order_date,
    o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products  p ON o.product_id  = p.product_id
WHERE o.status = 'Completed'
ORDER BY o.order_date DESC;

-- Example: Employee with department and their manager's name
SELECT
    e.name              AS employee,
    d.dept_name,
    m.name              AS manager_name,
    e.salary
FROM employees e
JOIN departments d  ON e.dept_id    = d.dept_id
LEFT JOIN employees m ON e.manager_id = m.emp_id  -- self-join for manager
ORDER BY d.dept_name, e.name;
```

---

## Pattern 11: CTE for Multi-Step Logic

**What it solves**: Break complex queries into readable, named steps. Avoids deeply nested subqueries.

```sql
-- Template
WITH step1 AS (
    SELECT ... FROM ... WHERE ...
),
step2 AS (
    SELECT ... FROM step1 WHERE ...
)
SELECT * FROM step2;
```

```sql
-- Example: Find departments where avg salary exceeds company-wide avg
WITH dept_avg AS (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
),
company_avg AS (
    SELECT AVG(salary) AS overall_avg FROM employees
)
SELECT d.dept_name,
       da.avg_salary,
       ca.overall_avg,
       da.avg_salary - ca.overall_avg AS above_average_by
FROM dept_avg da
JOIN departments d  ON da.dept_id = d.dept_id
CROSS JOIN company_avg ca
WHERE da.avg_salary > ca.overall_avg
ORDER BY above_average_by DESC;
```

---

## Pattern 12: Self-Join (Employee–Manager Relationship)

**What it solves**: A table that references itself — employees with managers, org hierarchy, bill of materials.

```sql
-- Template
SELECT e.name AS entity, m.name AS parent
FROM table e
LEFT JOIN table m ON e.parent_id = m.id;
```

```sql
-- Example: List each employee and their manager's name
SELECT
    e.emp_id,
    e.name                                    AS employee,
    COALESCE(m.name, 'No Manager (Top Level)') AS manager,
    e.salary                                  AS emp_salary,
    m.salary                                  AS mgr_salary
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY e.dept_id, e.emp_id;

-- Example: Employees earning more than their manager
SELECT e.name AS employee, e.salary,
       m.name AS manager, m.salary AS mgr_salary
FROM employees e
JOIN employees m ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;
```

---

## Pattern at a Glance

| # | Pattern | Key SQL Clause | When to Use |
|---|---|---|---|
| 1 | Aggregation + GROUP BY | `GROUP BY`, `SUM/COUNT/AVG` | Per-group totals |
| 2 | Filter after aggregation | `HAVING` | Aggregate conditions |
| 3 | Top-N per group | `ROW_NUMBER/DENSE_RANK OVER (PARTITION BY)` | Best/worst per category |
| 4 | Anti-join | `LEFT JOIN IS NULL` / `NOT EXISTS` | "Has no matching record" |
| 5 | Semi-join | `EXISTS` / `IN` | "Has at least one match" |
| 6 | Running total | `SUM() OVER (ORDER BY)` | Cumulative metrics |
| 7 | Period comparison | `LAG() / LEAD()` | Change over time |
| 8 | Deduplication | `ROW_NUMBER() OVER (PARTITION BY)` | One row per group |
| 9 | Conditional aggregation | `SUM(CASE WHEN ...)` | Pivot / breakdown by condition |
| 10 | Multi-table join | `JOIN ... JOIN` | Combining related tables |
| 11 | Multi-step CTE | `WITH ... AS (...)` | Complex logic, readable steps |
| 12 | Self-join | `JOIN table AS alias ON id = parent_id` | Hierarchical data |

---

## Interview Tips

1. **Identify the pattern first** — Before writing SQL, say aloud which pattern applies. Interviewers appreciate structured thinking over brute-force coding.

2. **HAVING vs WHERE** is tested constantly — A quick answer: "WHERE filters rows before grouping; HAVING filters the result of GROUP BY." Know this cold.

3. **Anti-join is a favourite** — "Customers who never ordered" is one of the most common questions. Know both `LEFT JOIN IS NULL` and `NOT EXISTS` — and explain why `NOT IN` can be dangerous with NULLs.

4. **CTEs signal maturity** — Using a CTE instead of a nested subquery shows you write production-quality SQL. Always prefer CTEs for multi-step logic.

5. **Self-join trips people up** — Aliases are essential. Practice the employee-manager self-join until it's automatic.

---

## ❓ Practice Questions

1. Find the **top-earning employee in each department** using a window function. Show department name, employee name, and salary.

2. List all **products that have never been ordered**. Use both the `LEFT JOIN IS NULL` approach and the `NOT EXISTS` approach.

3. Write a query showing **monthly revenue and the running cumulative revenue** across all months. Order chronologically.

4. Find **customers who placed orders in both 2023 and 2024**. (Hint: semi-join or conditional aggregation.)

5. Using the `performance` table, write a query showing each employee's **most recent year's rating and bonus**. If an employee has no performance record, show NULLs. (Hint: deduplication pattern + LEFT JOIN.)
