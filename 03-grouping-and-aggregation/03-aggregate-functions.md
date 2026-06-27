# Aggregate Functions — COUNT, SUM, AVG, MIN, MAX

> **Interview Priority**: 🔴 Must Know

## What Is It?

Aggregate functions compute a **single result** from a set of rows. They are the backbone of reporting and analytics in SQL — counting records, summing revenue, finding extremes, and computing averages. They're used in `SELECT`, `HAVING`, and sometimes in window functions. Understanding their NULL behaviour and the subtle differences between `COUNT(*)`, `COUNT(col)`, and `COUNT(DISTINCT col)` is a top interview priority.

## Syntax

```sql
COUNT(*)               -- count all rows (including NULLs)
COUNT(column)          -- count non-NULL values in column
COUNT(DISTINCT column) -- count distinct non-NULL values

SUM(column)            -- total of non-NULL values
SUM(DISTINCT column)   -- sum of distinct non-NULL values

AVG(column)            -- mean of non-NULL values (NOT divided by total rows)
AVG(DISTINCT column)   -- mean of distinct non-NULL values

MIN(column)            -- smallest non-NULL value
MAX(column)            -- largest non-NULL value
```

## Key Concepts

### NULL Behaviour — The Most Tested Rule

> **All aggregate functions ignore NULLs — except `COUNT(*)`.**

| Function | NULL handling |
|---|---|
| `COUNT(*)` | Counts every row regardless of NULLs |
| `COUNT(col)` | Skips rows where col IS NULL |
| `COUNT(DISTINCT col)` | Skips NULLs, then counts unique values |
| `SUM(col)` | Ignores NULLs; `SUM` of all-NULL set is `NULL`, not 0 |
| `AVG(col)` | Ignores NULLs; divides sum by *count of non-NULL rows*, not total rows |
| `MIN(col)` | Ignores NULLs |
| `MAX(col)` | Ignores NULLs |

**Critical AVG trap**: If 5 employees have salaries `[80000, 90000, NULL, NULL, NULL]`:
- `AVG(salary)` = `(80000 + 90000) / 2` = **85000** — NULLs are excluded from both numerator and denominator.
- This is often **not** what you want if NULL means "0 salary". Use `AVG(COALESCE(salary, 0))` to include zeros.

### COUNT(*) vs COUNT(col) vs COUNT(DISTINCT col)

```sql
-- Suppose bonus column has values: 5000, 8000, NULL, 5000, NULL

COUNT(*)               -- 5  (all rows)
COUNT(bonus)           -- 3  (non-NULL only)
COUNT(DISTINCT bonus)  -- 2  (distinct non-NULL: 5000 and 8000)
```

### DISTINCT Inside Aggregates

You can use `DISTINCT` inside any aggregate to operate only on unique values:
- `SUM(DISTINCT col)`: sums each unique value once (rarely useful, but valid)
- `AVG(DISTINCT col)`: average of distinct values
- `COUNT(DISTINCT col)`: most common — count of unique non-NULL values

### SUM of an All-NULL Set Returns NULL, Not 0

```sql
-- If all employees in a dept have NULL salary:
SELECT SUM(salary) FROM employees WHERE dept_id = 99;
-- Returns NULL, not 0

-- Use COALESCE to treat it as 0:
SELECT COALESCE(SUM(salary), 0) FROM employees WHERE dept_id = 99;
```

### Aggregates Without GROUP BY

When used without `GROUP BY`, aggregate functions collapse the **entire result set** into a single row.

```sql
SELECT COUNT(*), SUM(salary), AVG(salary) FROM employees;
-- One row: total count, total salary, avg salary across all employees
```

### MIN/MAX on Strings and Dates

`MIN` and `MAX` work on strings (lexicographic order) and dates (chronological order), not just numbers.

## Examples

### 1 — Basic aggregate overview on employees

```sql
SELECT
    COUNT(*)               AS total_employees,       -- 5
    COUNT(manager_id)      AS employees_with_manager, -- fewer if some mgr_id is NULL
    COUNT(DISTINCT dept_id) AS num_departments,       -- 4
    SUM(salary)            AS total_payroll,
    ROUND(AVG(salary), 2)  AS avg_salary,
    MIN(salary)            AS lowest_salary,
    MAX(salary)            AS highest_salary
FROM employees;

-- Result:
-- total_employees | employees_with_manager | num_departments | total_payroll | avg_salary | lowest_salary | highest_salary
--       5         |          4             |        4        |    390000     |   78000    |     62000     |    91000
```

### 2 — COUNT(*) vs COUNT(col) — the NULL difference

```sql
-- Suppose 2 employees have NULL manager_id (top-level)
SELECT
    COUNT(*)           AS all_rows,      -- 5
    COUNT(manager_id)  AS has_manager    -- 3 (if 2 are NULL)
FROM employees;
```

### 3 — COUNT(DISTINCT) — how many departments have employees

```sql
SELECT COUNT(DISTINCT dept_id) AS active_departments
FROM employees;

-- 4 (Engineering, HR, Finance, Marketing)
```

### 4 — SUM and AVG per department

```sql
SELECT dept_id,
       COUNT(*)              AS headcount,
       SUM(salary)           AS total_salary,
       ROUND(AVG(salary), 0) AS avg_salary
FROM employees
GROUP BY dept_id
ORDER BY total_salary DESC;

-- Result:
-- dept_id | headcount | total_salary | avg_salary
-- --------+-----------+--------------+-----------
-- 10      | 2         | 163000       | 81500
-- 30      | 1         | 91000        | 91000
-- 40      | 1         | 74000        | 74000
-- 20      | 1         | 62000        | 62000
```

### 5 — AVG NULL trap: including vs excluding NULLs

```sql
-- Suppose some employees have NULL bonus in performance table
-- AVG(bonus) only averages rows where bonus IS NOT NULL:
SELECT emp_id, AVG(bonus) AS avg_bonus_excl_null
FROM performance
GROUP BY emp_id;

-- To treat NULL bonus as 0 (include in denominator):
SELECT emp_id, AVG(COALESCE(bonus, 0)) AS avg_bonus_incl_null
FROM performance
GROUP BY emp_id;
```

### 6 — SUM returns NULL when all values are NULL — use COALESCE

```sql
SELECT dept_id,
       COALESCE(SUM(salary), 0) AS safe_total_salary
FROM employees
GROUP BY dept_id;
```

### 7 — MIN and MAX on dates (earliest and latest hire)

```sql
SELECT dept_id,
       MIN(hire_date) AS first_hire,
       MAX(hire_date) AS latest_hire
FROM employees
GROUP BY dept_id;
```

### 8 — MIN and MAX on strings (alphabetical first and last employee name)

```sql
SELECT MIN(name) AS first_alphabetically,
       MAX(name) AS last_alphabetically
FROM employees;

-- MIN: 'Aman', MAX: 'Zara'
```

### 9 — COUNT(DISTINCT) for unique products ordered per customer

```sql
SELECT customer_id,
       COUNT(order_id)          AS total_orders,
       COUNT(DISTINCT product_id) AS unique_products_ordered,
       SUM(amount)              AS total_spent
FROM orders
GROUP BY customer_id;
```

### 10 — DISTINCT inside SUM (unusual but valid)

```sql
-- Sum only distinct salary values (treats duplicates as one)
SELECT dept_id, SUM(DISTINCT salary) AS sum_distinct_salaries
FROM employees
GROUP BY dept_id;

-- In Engineering: Aman=85000, Dev=78000 → SUM = 163000 (no duplicates here)
-- If two employees both earned 78000, SUM(DISTINCT) would count 78000 only once
```

### 11 — Using aggregates in HAVING (correct pattern)

```sql
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > 75000;

-- Only Engineering (81500) and Finance (91000) qualify
```

### 12 — Aggregate on performance table — who gets the highest average bonus?

```sql
SELECT e.name,
       COUNT(p.perf_id)    AS review_count,
       AVG(p.bonus)        AS avg_bonus,
       MAX(p.bonus)        AS best_bonus
FROM employees e
LEFT JOIN performance p ON p.emp_id = e.emp_id
GROUP BY e.emp_id, e.name
ORDER BY avg_bonus DESC;
```

## Aggregate Functions Summary Table

| Function | Input | NULL rows | Result type |
|---|---|---|---|
| `COUNT(*)` | All rows | Included | INTEGER |
| `COUNT(col)` | Non-NULL rows | Excluded | INTEGER |
| `COUNT(DISTINCT col)` | Distinct non-NULL rows | Excluded | INTEGER |
| `SUM(col)` | Non-NULL values | Ignored | Same as col (or NULL if all NULL) |
| `AVG(col)` | Non-NULL values | Ignored (from denominator too) | DECIMAL/FLOAT |
| `MIN(col)` | Non-NULL values | Ignored | Same as col |
| `MAX(col)` | Non-NULL values | Ignored | Same as col |

## Interview Tips

1. **`COUNT(*) vs COUNT(col)`**: `COUNT(*)` counts all rows including those with NULLs; `COUNT(col)` skips rows where that column is NULL. This difference is one of the most frequently asked SQL nuances.
2. **AVG ignores NULLs in the denominator**: If 5 rows exist but 2 have NULL salary, `AVG(salary)` divides by 3, not 5. This surprises many candidates. Ask: "should NULLs be treated as 0?" If yes, use `AVG(COALESCE(col, 0))`.
3. **SUM of NULLs is NULL, not 0**: Always wrap with `COALESCE(SUM(col), 0)` if a zero result matters to your application logic.
4. **`COUNT(DISTINCT col)` cannot be used in most window functions** — you cannot do `COUNT(DISTINCT col) OVER (PARTITION BY ...)` in standard SQL. Interviewers test this. Workaround: use a subquery or `DENSE_RANK`.
5. **Aggregates can be nested in subqueries but not in the same SELECT level**: `SELECT MAX(AVG(salary)) FROM employees GROUP BY dept_id` is invalid in one step — you need a subquery or CTE to get the max of averages.

## ❓ Practice Questions

1. Write a query to find the **total number of orders**, **number of distinct customers** who placed orders, and the **average order amount** from the `orders` table. Do this in a single `SELECT` statement.
```sql
SELECT
    COUNT(*),
    COUNT(DISTINCT customers),
    AVG(amount)
FROM orders

```

3. In the `performance` table, some employees may have `NULL` values for `bonus`. Write two queries: one that computes the average bonus **excluding NULLs** (default behaviour) and one that **treats NULL as 0** when computing the average. Explain the difference in results.

```sql
SELECT
    AVG(bonus)
FROM performance

or
SELECT
    AVG(COALESCE(bonus,0))
FROM performance

```

5. Write a query that returns — for each `dept_id` — the **count of all employees**, the **count of employees who have a manager** (non-NULL `manager_id`), and the **difference** between the two (i.e., how many are top-level).

```sql
SELECT
    dept_id,
    COUNT(*) AS total_employees,
    COUNT(manager_id) AS employees_with_manager,
    total_employees - employees_with_manager
FROM employees
GROUP BY dept_id;

```

7. From the `orders` table, find each `customer_id` along with the **number of distinct products** they have ordered, and the **total amount spent**. Filter to only include customers who have ordered **at least 2 distinct products**.
```sql
SELECT
    customer_id,
    COUNT(DISTINCT product_id) AS distinct_products,
    SUM(amount) AS total_amount_spent
FROM orders
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) >= 2;
```

9. Write a query using `MIN` and `MAX` on the `hire_date` column of `employees` to find — per `dept_id` — the **earliest** and **most recent** hire date. Also compute the number of days between them (`DATEDIFF` or `MAX(hire_date) - MIN(hire_date)`).
```sql
SELECT
    dept_id,
    MIN(hire_date) AS earliest,
    MAX(hire_date) AS most_recent,
    DATEDIFF(MAX(hire_date), MIN(hire_date)) AS days_between
FROM employees
GROUP BY dept_id;
```
