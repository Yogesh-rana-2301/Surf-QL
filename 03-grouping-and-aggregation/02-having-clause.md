# HAVING Clause — Filtering Groups After Aggregation

> **Interview Priority**: 🔴 Must Know

## What Is It?

`HAVING` is the filter clause for **groups** — it does what `WHERE` does for individual rows, but it runs *after* `GROUP BY` and *after* aggregate functions are computed. This makes `HAVING` the only place where you can legally filter using aggregate expressions like `SUM(salary) > 100000` or `COUNT(*) >= 3`.

## Syntax

```sql
SELECT   column, aggregate_function(col)
FROM     table_name
[WHERE   row_level_condition]
GROUP BY column
HAVING   group_level_condition
[ORDER BY column];
```

## Key Concepts

### WHERE vs HAVING — The Core Distinction

| Feature | WHERE | HAVING |
|---|---|---|
| Filters | **Individual rows** | **Groups** |
| Runs at stage | Before GROUP BY | After GROUP BY |
| Can use aggregates? | **No** | **Yes** |
| Can use non-aggregated columns? | Yes | Yes (if in GROUP BY) |
| Runs without GROUP BY? | Yes | Yes (treats whole table as one group) |
| Performance | Faster — reduces rows before grouping | Slower — aggregation happens first |

### Execution Order Reminder

```
WHERE  →  GROUP BY  →  HAVING  →  SELECT  →  ORDER BY
```

- `WHERE` reduces the **row pool** before aggregation.
- `HAVING` filters **computed groups** after aggregation.
- Using both together: `WHERE` first to trim unnecessary rows, then `HAVING` to trim groups — this is the most efficient pattern.

### Classic Mistake: Using WHERE with Aggregates

```sql
-- ❌ WRONG — cannot use SUM() in WHERE
SELECT dept_id, SUM(salary)
FROM employees
WHERE SUM(salary) > 100000   -- Error: aggregate not allowed in WHERE
GROUP BY dept_id;

-- ✅ CORRECT — use HAVING for aggregate conditions
SELECT dept_id, SUM(salary)
FROM employees
GROUP BY dept_id
HAVING SUM(salary) > 100000;
```

### HAVING Without GROUP BY

`HAVING` can technically be used without `GROUP BY`. In that case, the entire result set is treated as one group, and `HAVING` filters whether that single group makes the cut.

```sql
-- Returns the one row if avg salary of ALL employees > 70000; otherwise nothing
SELECT AVG(salary) AS avg_salary
FROM employees
HAVING AVG(salary) > 70000;
```

## Examples

### 1 — Departments with more than 1 employee

```sql
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 1;

-- Result:
-- dept_id | headcount
-- --------+----------
-- 10      | 2         (Engineering: Aman + Dev)
```

### 2 — Departments with total salary exceeding 100,000

```sql
SELECT dept_id, SUM(salary) AS total_salary
FROM employees
GROUP BY dept_id
HAVING SUM(salary) > 100000;

-- dept_id | total_salary
-- --------+-------------
-- 10      | 163000   (Aman 85000 + Dev 78000)
```

### 3 — Departments where average salary is between 70,000 and 90,000

```sql
SELECT dept_id, ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) BETWEEN 70000 AND 90000;

-- dept_id | avg_salary
-- --------+-----------
-- 10      | 81500    (Engineering: (85000+78000)/2)
-- 40      | 74000    (Marketing: Zara alone)
```

### 4 — WHERE + GROUP BY + HAVING together (most common real-world pattern)

```sql
-- Among employees hired after 2020, find departments
-- where the average salary exceeds 75000.
SELECT dept_id,
       COUNT(*)      AS headcount,
       AVG(salary)   AS avg_salary
FROM employees
WHERE hire_date > '2020-01-01'   -- row-level filter first
GROUP BY dept_id
HAVING AVG(salary) > 75000;     -- group-level filter after
```

**Step-by-step what happens**:
1. `FROM employees` — load all employees
2. `WHERE hire_date > '2020-01-01'` — keep only recently hired employees
3. `GROUP BY dept_id` — group the remaining rows by department
4. Compute `COUNT(*)` and `AVG(salary)` per group
5. `HAVING AVG(salary) > 75000` — keep only groups whose average salary is above 75,000
6. `SELECT` — project the output columns

### 5 — Customers with more than 3 orders

```sql
SELECT customer_id, COUNT(*) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 3
ORDER BY total_orders DESC;
```

### 6 — Products categories with total revenue above a threshold

```sql
SELECT p.category,
       COUNT(o.order_id)  AS num_orders,
       SUM(o.amount)      AS total_revenue
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY p.category
HAVING SUM(o.amount) > 50000
ORDER BY total_revenue DESC;
```

### 7 — Employees who appeared in performance reviews for more than 1 year

```sql
SELECT emp_id, COUNT(DISTINCT year) AS years_reviewed
FROM performance
GROUP BY emp_id
HAVING COUNT(DISTINCT year) > 1;
```

### 8 — Departments where MAX salary is more than 2× MIN salary (salary spread)

```sql
SELECT dept_id,
       MAX(salary) AS max_sal,
       MIN(salary) AS min_sal
FROM employees
GROUP BY dept_id
HAVING MAX(salary) > 2 * MIN(salary);
```

### 9 — The classic mistake — WHERE with aggregate, and the correct fix

```sql
-- ❌ Wrong: SUM in WHERE
SELECT dept_id, SUM(salary) AS total
FROM employees
WHERE SUM(salary) > 150000    -- Error!
GROUP BY dept_id;

-- ✅ Fix: move aggregate condition to HAVING
SELECT dept_id, SUM(salary) AS total
FROM employees
GROUP BY dept_id
HAVING SUM(salary) > 150000;

-- Tip: also think about whether you should filter rows first with WHERE
-- E.g., if you only care about full-time employees:
SELECT dept_id, SUM(salary) AS total
FROM employees
WHERE employment_type = 'Full-Time'   -- row-level filter
GROUP BY dept_id
HAVING SUM(salary) > 150000;          -- group-level filter
```

### 10 — HAVING with alias (PostgreSQL allows it, standard SQL does not)

```sql
-- Standard SQL: must repeat the expression
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id
HAVING COUNT(*) >= 2;   -- repeat COUNT(*), not alias 'headcount'

-- PostgreSQL extension (alias in HAVING — non-standard but supported):
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id
HAVING headcount >= 2;  -- works in PostgreSQL only
```

## Interview Tips

1. **"What is the difference between WHERE and HAVING?"** — This is asked in almost every SQL interview. Memorize: `WHERE` filters rows before grouping; `HAVING` filters groups after aggregation. `WHERE` cannot use aggregates; `HAVING` can.
2. **Performance mindset**: Always filter with `WHERE` first to reduce row count before grouping. Using `HAVING` to filter something you could have filtered in `WHERE` wastes computation. E.g., `HAVING dept_id = 10` should be `WHERE dept_id = 10`.
3. **Can you use HAVING without GROUP BY?** — Yes. The whole table acts as one group. Ask the interviewer if they're testing this edge case.
4. **Alias in HAVING**: Standard SQL does not allow aliases from `SELECT` in `HAVING` (same reason as `GROUP BY` — execution order). Repeat the aggregate expression. PostgreSQL allows aliases; MySQL sometimes does too.
5. **HAVING COUNT(*) vs HAVING COUNT(col)**: These differ when the grouped column has NULLs. `COUNT(*)` counts all rows; `COUNT(col)` skips NULLs. This subtlety can change your group filter results.

## ❓ Practice Questions

1. Find all departments where the **minimum salary** is above 65,000. Show `dept_id` and the minimum salary.

2. Write a query to find all customers who have placed **at least 2 orders** with a total `amount` greater than **5,000**. Use both `COUNT` and `SUM` in `HAVING`.

3. From the `performance` table, find all employees whose **average bonus** across all years is greater than **10,000** and who have been reviewed in **at least 2 different years**.

4. A product manager wants to see all product `category` groups where the **average price** is above 1,000 AND the **number of products** in that category is at least 3. Write the query.

5. Explain the bug in this query and fix it:
   ```sql
   SELECT dept_id, AVG(salary) AS avg_sal
   FROM employees
   WHERE AVG(salary) > 80000
   GROUP BY dept_id;
   ```
   What error does it produce, and what is the correct version?
