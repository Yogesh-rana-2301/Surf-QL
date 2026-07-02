# Advanced Join Patterns — Beyond the Basic Join

> **Interview Priority**: 🔴 Must Know (Semi/Anti Join) | 🟡 Important (Lateral, Non-equi, Multi-table) | 🟢 Good to Know (Performance deep-dive)

---

## What Is It?

Once you know INNER, OUTER, CROSS, and SELF joins, the next tier of SQL mastery is **join patterns** — idiomatic ways to express complex data relationships. These include:

- **Semi Join** — return left-side rows that have at least one match on the right
- **Anti Join** — return left-side rows that have **no** match on the right
- **Lateral Join / CROSS APPLY** — a subquery in the `FROM` clause that can reference the outer row
- **Non-equi Join** — a join whose condition uses `<`, `>`, `BETWEEN`, or `!=` instead of `=`
- **Row multiplication in one-to-many joins** — understanding and handling the "fan-out" problem
- **Multi-table joins** — chaining 3+ tables correctly
- **Join performance tips** — indexing, EXPLAIN, and optimizer awareness

---

## 1. Semi Join — Does a Match Exist?

A **Semi Join** returns rows from the **left table** for which at least one matching row exists in the right table — but it does **not** return any columns from the right table, and it does **not** multiply rows even if multiple matches exist.

SQL has no explicit `SEMI JOIN` keyword. It is expressed using:
- `EXISTS` (most common and recommended)
- `IN` (equivalent, but can behave differently with NULLs)

### When to use
- "Find all X that have at least one Y" — without needing any columns from Y.
- More efficient than JOIN + DISTINCT because the engine can stop scanning the right side after the first match.

### Syntax

```sql
-- Semi join using EXISTS (preferred)
SELECT columns
FROM   left_table l
WHERE  EXISTS (
    SELECT 1
    FROM   right_table r
    WHERE  r.fk = l.pk
    -- additional conditions here
);

-- Semi join using IN (equivalent for non-NULL keys)
SELECT columns
FROM   left_table
WHERE  pk IN (SELECT fk FROM right_table);
```

### Example — Customers Who Have Placed At Least One Order

```sql
-- EXISTS version (Semi Join)
SELECT
    c.customer_id,
    c.name,
    c.city
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

**Sample Output:**

```
customer_id | name        | city
------------|-------------|----------
1           | Arjun Mehta | Mumbai
2           | Sneha Patel | Bangalore
3           | Kavya Nair  | Chennai
```

> Rohan Desai and Meena Iyer have no orders → not returned. Even if Arjun had 10 orders, he appears **exactly once** — no row multiplication.

---

```sql
-- Equivalent using IN
SELECT customer_id, name, city
FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);
```

### EXISTS vs IN — The NULL trap

```sql
-- ⚠️ IN with NULLs — dangerous!
-- If the subquery returns any NULL, "NOT IN" returns no rows at all.
SELECT name FROM employees
WHERE emp_id NOT IN (SELECT manager_id FROM employees);
-- If ANY manager_id is NULL, this returns ZERO rows — a silent bug!

-- ✅ Safe: NOT EXISTS always handles NULLs correctly
SELECT name FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM employees m WHERE m.manager_id = e.emp_id
);
```

> **Always prefer `NOT EXISTS` over `NOT IN`** when the subquery column could contain NULLs. `EXISTS` never has this problem.

---

### Example — Employees Who Have a Performance Record

```sql
SELECT
    e.emp_id,
    e.name,
    e.salary
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM performance p
    WHERE p.emp_id = e.emp_id
);
```

---

## 2. Anti Join — Find Rows With NO Match

An **Anti Join** is the complement of a Semi Join: it returns left-side rows for which **no matching row** exists in the right table. Implemented using:
- `NOT EXISTS` (recommended)
- `LEFT JOIN ... WHERE right_col IS NULL`
- `NOT IN` (avoid when NULLs possible — see above)

### Syntax

```sql
-- Anti join using NOT EXISTS (preferred)
SELECT columns
FROM   left_table l
WHERE  NOT EXISTS (
    SELECT 1
    FROM   right_table r
    WHERE  r.fk = l.pk
);

-- Anti join using LEFT JOIN + IS NULL
SELECT l.columns
FROM   left_table l
LEFT JOIN right_table r
    ON l.pk = r.fk
WHERE  r.fk IS NULL;
```

### Example — Customers Who Have NEVER Ordered

```sql
-- NOT EXISTS version
SELECT c.customer_id, c.name, c.city
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- LEFT JOIN + IS NULL version (equivalent)
SELECT c.customer_id, c.name, c.city
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

**Sample Output (both produce the same result):**

```
customer_id | name        | city
------------|-------------|-------
4           | Rohan Desai | Delhi
5           | Meena Iyer  | Hyderabad
```

---

### Example — Employees With No Performance Record in 2023

```sql
SELECT e.emp_id, e.name, e.dept_id
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM performance p
    WHERE p.emp_id = p.emp_id
      AND p.year   = 2023
);
```

---

### Semi vs Anti vs INNER JOIN — Quick Comparison

| Pattern | Returns | Duplicates | Right-side columns |
|---|---|---|---|
| INNER JOIN | Matched rows from both sides | Yes (one-to-many) | ✅ Yes |
| Semi Join (EXISTS) | Left rows with ≥1 match | No | ❌ No |
| Anti Join (NOT EXISTS) | Left rows with 0 matches | No | ❌ No |

---

## 3. Lateral Join / CROSS APPLY — Subquery That References the Outer Row

A **Lateral Join** (PostgreSQL/standard SQL) or **CROSS APPLY** (SQL Server) allows a subquery in the `FROM` clause to **reference columns from the preceding table**. A normal subquery in `FROM` is evaluated independently; a lateral subquery is re-evaluated for each row of the outer query.

> **Think of it as**: "For each row on the left, run this subquery using values from that row."

### Syntax

```sql
-- PostgreSQL / standard SQL
SELECT l.col, sub.col
FROM   left_table l
CROSS JOIN LATERAL (
    SELECT ...
    FROM   right_table r
    WHERE  r.fk = l.pk          -- references outer row's column
    LIMIT  3
) sub;

-- SQL Server equivalent
SELECT l.col, sub.col
FROM   left_table l
CROSS APPLY (
    SELECT TOP 3 ...
    FROM   right_table r
    WHERE  r.fk = l.pk
) sub;

-- LEFT JOIN LATERAL / OUTER APPLY: includes outer rows even if subquery returns no rows
SELECT l.col, sub.col
FROM   left_table l
LEFT JOIN LATERAL (...) sub ON true;  -- PostgreSQL

-- SQL Server
SELECT l.col, sub.col
FROM   left_table l
OUTER APPLY (...) sub;
```

### Example — Each Employee's Most Recent Performance Record

```sql
-- PostgreSQL: for each employee, get their latest performance record
SELECT
    e.emp_id,
    e.name,
    latest.year,
    latest.rating,
    latest.bonus
FROM employees e
CROSS JOIN LATERAL (
    SELECT year, rating, bonus
    FROM   performance p
    WHERE  p.emp_id = e.emp_id      -- references outer row
    ORDER BY p.year DESC
    LIMIT  1
) latest;
```

**Sample Output:**

```
emp_id | name  | year | rating | bonus
-------|-------|------|--------|--------
1      | Aman  | 2023 | A      | 12000
2      | Priya | 2023 | B      | 7000
3      | Ravi  | 2023 | A      | 15000
5      | Dev   | 2022 | C      | 3000
```

> Without `LATERAL`, you'd have to use a correlated subquery in `SELECT` (limited to one value) or use `ROW_NUMBER()` window function. Lateral join gives you multiple columns from the "top N per group" result naturally.

---

### Example — Top 2 Orders Per Customer

```sql
-- PostgreSQL: for each customer, get their 2 most valuable orders
SELECT
    c.customer_id,
    c.name,
    top_orders.order_id,
    top_orders.amount
FROM customers c
CROSS JOIN LATERAL (
    SELECT order_id, amount
    FROM   orders o
    WHERE  o.customer_id = c.customer_id
    ORDER BY o.amount DESC
    LIMIT 2
) top_orders;
```

---

## 4. Non-Equi Join — Joins Without `=`

A **Non-equi join** uses a condition other than `=` in the `ON` clause: `<`, `>`, `<=`, `>=`, `BETWEEN`, or `!=`. They join rows not by exact key match, but by a range or inequality relationship.

### Common Use Cases
- Salary banding (match employee salary to a salary grade range)
- Date range overlaps (is a date within a valid range?)
- Overlap detection (do two date ranges intersect?)
- Version ranges, price tiers

### Example — Match Employees to a Salary Grade

```sql
-- Salary grade table (hypothetical):
-- salary_grades (grade CHAR(1), min_salary INT, max_salary INT)
-- A: 80000-100000, B: 60000-79999, C: 40000-59999

SELECT
    e.name,
    e.salary,
    sg.grade
FROM employees e
JOIN salary_grades sg
    ON e.salary BETWEEN sg.min_salary AND sg.max_salary;
```

**Sample Output:**

```
name  | salary   | grade
------|----------|------
Aman  | 85000.00 | A
Priya | 62000.00 | B
Ravi  | 91000.00 | A
Zara  | 74000.00 | B
Dev   | 78000.00 | B
Nisha | 55000.00 | C
```

---

### Example — Find Employees Hired Before Their Manager

```sql
-- Compare hire dates within the employees table (SELF + Non-equi join)
SELECT
    e.name          AS employee_name,
    e.hire_date     AS emp_hire_date,
    mgr.name        AS manager_name,
    mgr.hire_date   AS mgr_hire_date
FROM employees e
JOIN employees mgr
    ON  e.manager_id    = mgr.emp_id        -- equi condition (relationship)
    AND e.hire_date     < mgr.hire_date;    -- non-equi condition (business logic)
```

> This mixes an equi-join condition (to define the relationship) with a non-equi condition (the business filter). You can mix both in one `ON` clause freely.

---

## 5. Row Multiplication in Joins — The Fan-Out Problem

When you join a table on the "one" side of a one-to-many relationship, each "one" row multiplies by the number of matching "many" rows. If you join on two "many" sides simultaneously, the explosion can be dramatic.

### Example — The Problem

```sql
-- Employee has multiple performance records (one per year)
SELECT
    e.emp_id,
    e.name,
    e.salary,
    COUNT(*) AS row_count
FROM employees e
JOIN performance p ON e.emp_id = p.emp_id
GROUP BY e.emp_id, e.name, e.salary;
```

```
emp_id | name  | salary   | row_count
-------|-------|----------|----------
1      | Aman  | 85000.00 | 3   ← 3 years of performance = 3 rows for Aman
2      | Priya | 62000.00 | 3
3      | Ravi  | 91000.00 | 3
```

**The bug this causes:**

```sql
-- WRONG: SUM(salary) is inflated because salary appears once per performance row
SELECT
    d.dept_name,
    SUM(e.salary) AS total_salary_budget  -- ← WRONG: counts salary 3x per employee!
FROM departments d
JOIN employees   e ON d.dept_id  = e.dept_id
JOIN performance p ON e.emp_id   = p.emp_id   -- ← fan-out: multiplies rows
GROUP BY d.dept_name;
```

**How to fix it — aggregate before joining:**

```sql
-- ✅ Aggregate performance BEFORE joining to employees
SELECT
    d.dept_name,
    SUM(e.salary)           AS total_salary_budget,
    AVG(p_agg.avg_rating)   AS dept_avg_perf
FROM departments d
JOIN employees e
    ON d.dept_id = e.dept_id
JOIN (
    SELECT emp_id, AVG(bonus) AS avg_bonus
    FROM   performance
    GROUP BY emp_id
) p_agg
    ON e.emp_id = p_agg.emp_id
GROUP BY d.dept_name;
```

> **Rule**: If you need to aggregate a value from a table, and that table is on the "many" side of a join, **aggregate it in a subquery or CTE first**, then join the aggregated result.

---

## 6. Multi-Table Joins — Chaining 3+ Tables

Joining more than two tables is an extension of two-table joins. SQL executes them left-to-right, building an intermediate result at each step.

### Example — Orders with Customer Name, Product Name, and Department of the Salesperson

```sql
SELECT
    o.order_id,
    c.name          AS customer_name,
    c.city,
    p.product_name,
    p.category,
    o.amount,
    o.status,
    o.order_date
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
INNER JOIN products p
    ON o.product_id  = p.product_id
ORDER BY o.order_date DESC;
```

---

### Example — Full Employee Context Report (4 Tables)

```sql
SELECT
    e.emp_id,
    e.name          AS employee_name,
    d.dept_name,
    d.location,
    mgr.name        AS manager_name,
    p.rating,
    p.bonus
FROM employees e
LEFT JOIN departments d
    ON e.dept_id     = d.dept_id
LEFT JOIN employees mgr
    ON e.manager_id  = mgr.emp_id
LEFT JOIN performance p
    ON e.emp_id      = p.emp_id
    AND p.year       = 2023
ORDER BY e.emp_id;
```

**Sample Output:**

```
emp_id | employee_name | dept_name   | location  | manager_name | rating | bonus
-------|---------------|-------------|-----------|--------------|--------|--------
1      | Aman          | Engineering | Bangalore | Ravi         | A      | 12000
2      | Priya         | HR          | Mumbai    | Ravi         | B      | 7000
3      | Ravi          | Finance     | Delhi     | NULL         | A      | 15000
4      | Zara          | Marketing   | Bangalore | Ravi         | B      | 9000
5      | Dev           | Engineering | Bangalore | Aman         | C      | 3000
6      | Nisha         | NULL        | NULL      | NULL         | NULL   | NULL
```

> All LEFT JOINs preserve employees who may lack a department, manager, or performance record for 2023. The `AND p.year = 2023` is in the `ON` clause (not WHERE) to avoid converting the LEFT JOIN to INNER JOIN.

---

## 7. Join Performance Tips

### Index Your Foreign Keys

```sql
-- Create indexes on FK columns used in join conditions
CREATE INDEX idx_employees_dept_id    ON employees(dept_id);
CREATE INDEX idx_orders_customer_id   ON orders(customer_id);
CREATE INDEX idx_orders_product_id    ON orders(product_id);
CREATE INDEX idx_performance_emp_id   ON performance(emp_id);
```

> Without indexes on join columns, the database does a **full table scan** for every row of the driving table. With indexes, it uses a **nested loop with index lookup** or a **hash join** — orders of magnitude faster on large tables.

---

### Use EXPLAIN / EXPLAIN ANALYZE

```sql
-- MySQL / PostgreSQL: see how the query optimizer will execute the join
EXPLAIN
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- PostgreSQL: see actual execution stats (run the query)
EXPLAIN ANALYZE
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```

**What to look for in EXPLAIN output:**

| Term | Meaning |
|---|---|
| `Seq Scan` | Full table scan — may need an index |
| `Index Scan` | Using an index — usually good |
| `Nested Loop` | Row-by-row lookup — good for small tables |
| `Hash Join` | Build hash table — good for large unsorted tables |
| `Merge Join` | Sort both sides then merge — good for already-sorted data |
| `rows=` | Estimated rows — large numbers here are a warning sign |

---

### Additional Performance Guidelines

```sql
-- ✅ Filter early: put restrictive WHERE conditions on large tables
-- Bad: JOIN everything, then filter
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 80000;

-- Better: pre-filter in a subquery/CTE (especially on very large tables)
WITH high_earners AS (
    SELECT emp_id, name, dept_id
    FROM employees
    WHERE salary > 80000      -- filtered BEFORE the join
)
SELECT h.name, d.dept_name
FROM high_earners h
JOIN departments d ON h.dept_id = d.dept_id;

-- ✅ Avoid functions on join columns (prevents index use)
-- Bad:
JOIN orders o ON YEAR(o.order_date) = 2024
-- Good:
JOIN orders o ON o.order_date BETWEEN '2024-01-01' AND '2024-12-31'

-- ✅ Use covering indexes for frequently joined+selected columns
CREATE INDEX idx_orders_covering
    ON orders(customer_id, order_id, amount, status);
-- This index "covers" a query joining on customer_id and selecting order_id, amount, status
-- The engine never needs to touch the main table rows.
```

---

## Interview Tips

1. **"What is a semi join?"** — A pattern (not a keyword) using `EXISTS` or `IN` that returns left-side rows with at least one match on the right, without duplicating rows or pulling right-side columns. More efficient than JOIN + DISTINCT for existence checks.

2. **"Why use NOT EXISTS instead of NOT IN?"** — `NOT IN` returns zero rows if the subquery has any NULL values (because `NULL != anything` evaluates to UNKNOWN). `NOT EXISTS` handles NULLs correctly and is always safe.

3. **"What is row multiplication in a join?"** — When you join a "one" row to multiple "many" rows, the one row appears multiple times in the result. This inflates aggregations like `SUM(salary)`. Fix it by aggregating the "many" side in a CTE/subquery before joining.

4. **"What is a lateral join?"** — A subquery in the `FROM` clause that can reference columns from a preceding table in the same `FROM` clause. It's re-evaluated once per outer row. Used for "top N per group" and row-wise custom computations.

5. **"How do you optimize a slow JOIN query?"** — Check with `EXPLAIN`: look for full table scans. Add indexes on foreign key columns. Filter early using CTEs. Avoid functions on join columns. Consider the join type (hash, nested loop, merge) and whether the query plan is sensible.

6. **"What is a non-equi join?"** — A join where the `ON` condition uses `<`, `>`, `BETWEEN`, or `!=`. Used for range lookups like salary bands, date ranges, or overlap detection.

---

## ❓ Practice Questions

1. Write a **Semi Join** query using `EXISTS` to find all customers who have placed at least one order with `status = 'Delivered'`. Then write the equivalent using `IN`. Explain why you would prefer `EXISTS`.
```sql
SELECT ...
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE c.customer_id = o.customer_id
    AND o.status = 'Delivered'
);

or

SELECT ...
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE status = 'Delivered'
);

```

3. Write an **Anti Join** query using both `NOT EXISTS` and `LEFT JOIN IS NULL` to find employees who have **no performance record** in the `performance` table. Verify both produce the same result.
```sql

SELECT ...
FROM employee e
WHERE NOT EXISTS (
    SELECT 1
    FROM performance p 
    WHERE e.emp_id=p.emp_id; 
);

or



SELECT
    e.emp_id,
    e.name
FROM employees e
LEFT JOIN performance p
    ON e.emp_id = p.emp_id
WHERE p.emp_id IS NULL;

```

5. You need to compute the **average bonus per department** for the year 2023, but notice that joining `employees` to `performance` before grouping inflates the salary sum. Write a correct query using a CTE or subquery to aggregate performance data first, then join to departments.
```sql

SELECT
    d.dept_name,
    AVG(p.avg_bonus) AS avg_bonus
FROM departments d
JOIN employees e
    ON d.dept_id = e.dept_id
JOIN (
    SELECT
        emp_id,
        AVG(bonus) AS avg_bonus
    FROM performance
    WHERE year = 2023
    GROUP BY emp_id
) p
    ON e.emp_id = p.emp_id
GROUP BY d.dept_name;
```

7. Using a **non-equi join**, assign each employee a salary grade label (`'High'` for salary ≥ 80000, `'Mid'` for 60000–79999, `'Low'` for < 60000) by joining employees to a hypothetical `salary_bands` table with `(label, min_sal, max_sal)` columns.
```sql
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    sb.label AS salary_grade
FROM employees e
JOIN salary_bands sb
    ON e.salary BETWEEN sb.min_sal AND sb.max_sal;
```

9. Write a **4-table join** query that returns each order's `order_id`, `order_date`, `status`, the customer's `name` and `city`, the product's `product_name` and `category`, and the product's `price`. Filter for only `'Electronics'` category products and orders placed in 2024.
```sql

SELECT
    o.order_id,
    o.order_date,
    o.status,
    c.name,
    c.city,
    p.product_name,
    p.category,
    p.price
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE p.category = 'Electronics'
  AND o.order_date >= '2024-01-01'
  AND o.order_date < '2025-01-01';

```
   
