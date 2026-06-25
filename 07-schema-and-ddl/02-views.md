# Views & Materialized Views — Virtual Tables That Simplify Complexity

> **Interview Priority**: 🔴 Must Know

## What Is It?

A **View** is a named, stored SQL query that behaves like a virtual table. It does **not store data** — every time you query a view, the underlying query re-executes. Views let you hide complexity, enforce security (expose only certain columns/rows), and present a stable interface over tables that may change.

A **Materialized View** is a view that **physically stores** the result of the query on disk. It trades staleness for speed — the data is pre-computed and reads are near-instant, but it must be explicitly refreshed to reflect changes in the underlying tables. Supported in PostgreSQL and Oracle; not natively in MySQL (simulated with tables + triggers).

---

## Syntax

```sql
-- Create a view
CREATE VIEW view_name AS
SELECT ...;

-- Query a view (same as querying a table)
SELECT * FROM view_name;

-- Replace an existing view (no need to DROP first)
CREATE OR REPLACE VIEW view_name AS
SELECT ...;

-- Drop a view
DROP VIEW view_name;
DROP VIEW IF EXISTS view_name;

-- ── Materialized Views (PostgreSQL) ──────────────────────────
CREATE MATERIALIZED VIEW mv_name AS
SELECT ...;

-- Refresh the stored data (required after underlying table changes)
REFRESH MATERIALIZED VIEW mv_name;

-- Refresh without locking reads (PostgreSQL 9.4+, requires UNIQUE index on MV)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_name;

-- Drop a materialized view
DROP MATERIALIZED VIEW mv_name;
```

---

## Key Concepts

### Regular Views
- **No data storage** — the view definition is stored; the query runs fresh each time you SELECT from it.
- **Always up-to-date** — because data isn't cached, you always see the latest state of the underlying tables.
- **Security layer** — grant users access to a view without granting access to the underlying sensitive table (e.g., expose `name` and `dept_id` but not `salary`).
- **Simplification** — wrap a complex multi-table join into a single named object so application code stays clean.
- **Updatable vs Non-Updatable Views:**
  - A view is **updatable** if it selects from a single table, has no `GROUP BY`, `DISTINCT`, `HAVING`, aggregate functions, or subqueries. You can `INSERT`, `UPDATE`, `DELETE` through it.
  - A view is **non-updatable** if it involves joins, aggregations, `UNION`, or derived columns. Writes are rejected.
- **`WITH CHECK OPTION`** — on updatable views, prevents INSERTs/UPDATEs that would make the row invisible through the view's WHERE clause.

### Materialized Views
- **Stores data physically** — the result set is written to disk like a real table.
- **Must be refreshed** — stale until you manually (or periodically) run `REFRESH MATERIALIZED VIEW`.
- **Much faster for heavy queries** — dashboards, reports, and complex aggregations benefit enormously.
- **Indexes can be created on them** — further boosting read performance.
- **Trade-off: freshness vs. performance** — choose based on how often data changes and how stale it can be.

---

## Examples

### 1. Basic View — employees with their department name

```sql
CREATE VIEW vw_employee_details AS
SELECT
    e.emp_id,
    e.name,
    d.dept_name,
    d.location,
    e.salary,
    e.hire_date
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Using the view (feels like querying a table)
SELECT * FROM vw_employee_details WHERE dept_name = 'Engineering';
-- Returns: Aman, Dev (Engineering, Bangalore)
```

### 2. Security View — hide salary, expose only public columns

```sql
CREATE VIEW vw_employee_public AS
SELECT emp_id, name, dept_id, email
FROM employees;

-- GRANT access to the view, not the underlying table
GRANT SELECT ON vw_employee_public TO readonly_user;
```

Now `readonly_user` cannot see salaries at all, even though the data sits in `employees`.

### 3. Aggregation View — department salary summary (non-updatable)

```sql
CREATE VIEW vw_dept_salary_summary AS
SELECT
    d.dept_name,
    COUNT(e.emp_id)      AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MAX(e.salary)        AS max_salary,
    MIN(e.salary)        AS min_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

-- Query it
SELECT * FROM vw_dept_salary_summary ORDER BY avg_salary DESC;
/*
dept_name    | headcount | avg_salary | max_salary | min_salary
-------------|-----------|------------|------------|----------
Finance      | 1         | 91000.00   | 91000.00   | 91000.00
Engineering  | 2         | 81500.00   | 85000.00   | 78000.00
Marketing    | 1         | 74000.00   | 74000.00   | 74000.00
HR           | 1         | 62000.00   | 62000.00   | 62000.00
*/
```

This view is **non-updatable** because it uses `GROUP BY` and aggregate functions.

### 4. CREATE OR REPLACE VIEW — modify without dropping

```sql
-- Original view
CREATE VIEW vw_employee_details AS
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Add hire_date without DROP + recreate
CREATE OR REPLACE VIEW vw_employee_details AS
SELECT e.emp_id, e.name, d.dept_name, e.hire_date
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```

> In PostgreSQL, `CREATE OR REPLACE VIEW` can only **add** new columns at the end — it cannot reorder or remove columns (that would break dependent objects). For structural changes, `DROP VIEW` + `CREATE VIEW` is needed.

### 5. Updatable View with WITH CHECK OPTION

```sql
CREATE VIEW vw_engineering_employees AS
SELECT emp_id, name, dept_id, salary
FROM employees
WHERE dept_id = 10
WITH CHECK OPTION;

-- ✅ This UPDATE is allowed (stays in Engineering)
UPDATE vw_engineering_employees
SET salary = 90000
WHERE emp_id = 1;

-- ❌ This INSERT is REJECTED (dept_id=20 would be invisible through this view)
INSERT INTO vw_engineering_employees (emp_id, name, dept_id, salary)
VALUES (99, 'Test', 20, 60000);
-- ERROR: new row violates check option for view
```

### 6. Dropping a View

```sql
DROP VIEW vw_employee_details;

-- Safe drop (no error if view doesn't exist)
DROP VIEW IF EXISTS vw_employee_details;

-- PostgreSQL: drop view and all dependent views
DROP VIEW vw_employee_details CASCADE;
```

### 7. Materialized View — monthly order revenue (PostgreSQL)

```sql
CREATE MATERIALIZED VIEW mv_monthly_revenue AS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(amount)                      AS total_revenue,
    COUNT(order_id)                  AS total_orders
FROM orders
WHERE status = 'Completed'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- Lightning-fast reads (data is pre-computed)
SELECT * FROM mv_monthly_revenue WHERE month >= '2024-01-01';

-- After new orders are inserted, refresh the MV:
REFRESH MATERIALIZED VIEW mv_monthly_revenue;

-- Non-blocking refresh (table stays readable during refresh)
-- Requires a unique index on the MV first:
CREATE UNIQUE INDEX ON mv_monthly_revenue (month);
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_revenue;
```

### 8. View vs Materialized View — performance comparison

```sql
-- Regular view: runs full aggregation on EVERY query
-- (slow if orders has 50M rows)
SELECT * FROM vw_monthly_revenue;

-- Materialized view: reads pre-stored rows (instant)
SELECT * FROM mv_monthly_revenue;
```

---

## View vs Table — When to Use Which?

| Factor | View | Table |
|---|---|---|
| Stores data | ❌ No | ✅ Yes |
| Always fresh | ✅ Yes | ✅ Yes (it IS the source) |
| Performance | Depends on query | Fast reads with indexes |
| Can be indexed | ❌ No (regular view) | ✅ Yes |
| Schema abstraction | ✅ Excellent | ❌ You expose raw structure |
| Security filtering | ✅ Column/row masking | ❌ All-or-nothing by default |
| Use for reports | ❌ Slow if complex | ✅ If pre-aggregated |

| Factor | View | Materialized View |
|---|---|---|
| Stores data | ❌ No | ✅ Yes |
| Always fresh | ✅ Yes | ❌ Until refreshed |
| Indexable | ❌ | ✅ |
| Best for | Simple abstractions, security | Heavy reports, dashboards |
| MySQL support | ✅ | ❌ (simulate with table) |
| PostgreSQL support | ✅ | ✅ |

---

## Interview Tips

1. **"What is a view and does it store data?"** — A view stores only the query definition, not the data. Every SELECT re-executes the query. This is the most common first question on views.

2. **"When would you use a view instead of just writing the query?"** — Reusability (many queries need the same join), security (hide sensitive columns), interface stability (application code doesn't change if underlying tables restructure), and query simplification.

3. **"What makes a view non-updatable?"** — Joins across multiple tables, GROUP BY, DISTINCT, aggregate functions (COUNT, SUM…), UNION, or subqueries in the SELECT. The database can't figure out which base row to modify.

4. **"What is a materialized view and when would you use it?"** — Physically stored query result. Use it when the underlying query is expensive (large aggregation, multi-table join) and the data doesn't need to be perfectly real-time. Common in analytics/BI dashboards.

5. **"What's the risk of using CREATE OR REPLACE VIEW?"** — In PostgreSQL, it silently swaps the definition. If existing application code relied on column order (via `SELECT *`), the replacement may break things. Also, if you reorder columns, it will error — you must DROP and recreate. Always prefer named column references over `SELECT *`.

---

## ❓ Practice Questions

1. Create a view called `vw_high_value_orders` that shows `order_id`, `customer name` (from the `customers` table), `product_name` (from `products`), `amount`, and `order_date` for all orders where `amount > 5000`. Then write the query to find the top 3 customers by total order value using this view.

2. Write a view called `vw_employee_performance` that joins `employees` and `performance` to show each employee's name, department (join to `departments`), year, rating, and bonus. Is this view updatable? Explain why or why not.

3. The HR team should only see `emp_id`, `name`, `dept_id`, and `hire_date` from `employees` — not salary or email. Create a view to enforce this, then write the GRANT statement to give the `hr_user` role SELECT access to that view.

4. Create a materialized view (PostgreSQL syntax) called `mv_product_sales` that computes the total revenue and total units sold per `product_name`. Include the `REFRESH` statement. What would happen to the MV data if you inserted 1000 new rows into `orders` without refreshing?

5. You have a view `vw_dept_salary_summary` (from the examples above). A junior developer tries to run `DELETE FROM vw_dept_salary_summary WHERE dept_name = 'HR'`. What happens and why? How would you explain the concept of updatable vs non-updatable views to them?
