# CASE Statement — Conditional Logic Inside SQL

> **Interview Priority**: 🔴 Must Know

## What Is It?

The `CASE` expression is SQL's version of an `if-else` or `switch` statement. It returns a value based on conditions and can appear anywhere a value is expected: `SELECT`, `ORDER BY`, `GROUP BY`, `WHERE`, `HAVING`, and even `UPDATE SET`. It is essential for salary banding, custom sorting, conditional aggregation (pivot-style reporting), and data cleaning.

## Syntax

### Simple CASE (equality checks against one column)

```sql
CASE column
    WHEN value1 THEN result1
    WHEN value2 THEN result2
    ...
    ELSE default_result
END
```

### Searched CASE (arbitrary conditions, most flexible)

```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ...
    ELSE default_result
END
```

- `ELSE` is optional; if omitted and no condition matches, the expression returns `NULL`.
- Conditions are evaluated **top-to-bottom** and the first matching branch is returned — subsequent branches are not evaluated (short-circuit).
- The `END` keyword closes every `CASE` block.

## Key Concepts

- **CASE is an expression, not a statement** — it returns a single value, not multiple rows or side effects.
- **Short-circuit evaluation**: SQL evaluates `WHEN` clauses in order. Once a match is found, it stops. Put the most common or most selective condition first.
- **Type consistency**: All `THEN` and `ELSE` branches must return the same (or compatible) data type. Mixing `INT` and `VARCHAR` causes a type error.
- **NULL handling**: `WHEN NULL THEN ...` in a simple CASE never matches (NULL ≠ NULL). Use searched CASE with `WHEN col IS NULL THEN ...` instead.
- **Nested CASE**: You can nest CASE inside another CASE, though this quickly becomes unreadable.
- **CASE in UPDATE**: Useful for batch conditional updates without running multiple UPDATE statements.
- **CASE for pivoting**: Using `CASE` inside aggregate functions (like `SUM(CASE WHEN ... END)`) is the classic way to pivot rows into columns.

## Examples

### 1 — Salary banding in SELECT (Searched CASE)

```sql
SELECT
    name,
    salary,
    CASE
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 75000 THEN 'Medium'
        ELSE                      'Low'
    END AS salary_band
FROM employees;

-- Result:
-- name  | salary | salary_band
-- ------+--------+------------
-- Aman  | 85000  | Medium
-- Priya | 62000  | Low
-- Ravi  | 91000  | High
-- Zara  | 74000  | Low
-- Dev   | 78000  | Medium
```

### 2 — Simple CASE (equality on dept_id)

```sql
SELECT
    name,
    dept_id,
    CASE dept_id
        WHEN 10 THEN 'Engineering'
        WHEN 20 THEN 'HR'
        WHEN 30 THEN 'Finance'
        WHEN 40 THEN 'Marketing'
        ELSE         'Unknown'
    END AS dept_name
FROM employees;
```

### 3 — CASE in ORDER BY (custom sort priority)

```sql
-- Show Finance employees first, then Engineering, then everyone else
SELECT name, dept_id, salary
FROM employees
ORDER BY
    CASE dept_id
        WHEN 30 THEN 1
        WHEN 10 THEN 2
        ELSE        3
    END ASC,
    salary DESC;
```

### 4 — CASE in GROUP BY (group by salary band)

```sql
SELECT
    CASE
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 75000 THEN 'Medium'
        ELSE                      'Low'
    END AS salary_band,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY
    CASE
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 75000 THEN 'Medium'
        ELSE                      'Low'
    END;

-- Result:
-- salary_band | employee_count | avg_salary
-- ------------+----------------+-----------
-- High        | 1              | 91000
-- Medium      | 2              | 81500
-- Low         | 2              | 68000
```

### 5 — CASE in UPDATE (batch conditional update)

```sql
-- Give a 10% raise to Engineering employees, 5% to all others
UPDATE employees
SET salary = salary * CASE
                          WHEN dept_id = 10 THEN 1.10
                          ELSE                   1.05
                      END;
```

### 6 — Conditional aggregation / Pivot-style (CASE inside SUM)

Count employees per department broken down by salary band — all in one query, without multiple queries.

```sql
SELECT
    dept_id,
    SUM(CASE WHEN salary >= 90000 THEN 1 ELSE 0 END) AS high_earners,
    SUM(CASE WHEN salary >= 75000 AND salary < 90000 THEN 1 ELSE 0 END) AS medium_earners,
    SUM(CASE WHEN salary  < 75000 THEN 1 ELSE 0 END) AS low_earners
FROM employees
GROUP BY dept_id;

-- Result:
-- dept_id | high_earners | medium_earners | low_earners
-- --------+--------------+----------------+------------
-- 10      | 0            | 2              | 0
-- 20      | 0            | 0              | 1
-- 30      | 1            | 0              | 0
-- 40      | 0            | 0              | 1
```

### 7 — Conditional aggregation on orders (pivot order status)

```sql
SELECT
    customer_id,
    COUNT(*)                                                   AS total_orders,
    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END)     AS delivered,
    SUM(CASE WHEN status = 'Shipped'   THEN 1 ELSE 0 END)     AS shipped,
    SUM(CASE WHEN status = 'Pending'   THEN 1 ELSE 0 END)     AS pending,
    SUM(CASE WHEN status = 'Delivered' THEN amount ELSE 0 END) AS delivered_revenue
FROM orders
GROUP BY customer_id;
```

### 8 — CASE with NULL handling

```sql
-- manager_id is NULL for top-level employees
SELECT
    name,
    CASE
        WHEN manager_id IS NULL THEN 'No Manager (Top Level)'
        ELSE CAST(manager_id AS VARCHAR)
    END AS manager_info
FROM employees;
```

### 9 — CASE in HAVING (filter aggregated bands)

```sql
-- Show departments where average salary band is 'High'
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) >= 90000;

-- Or more explicitly using CASE logic
SELECT dept_id,
       CASE WHEN AVG(salary) >= 90000 THEN 'High'
            WHEN AVG(salary) >= 75000 THEN 'Medium'
            ELSE 'Low' END AS dept_salary_band
FROM employees
GROUP BY dept_id
HAVING AVG(salary) >= 75000;
```

### 10 — Performance rating label from performance table

```sql
SELECT
    e.name,
    p.year,
    p.rating,
    CASE p.rating
        WHEN 'A' THEN 'Excellent'
        WHEN 'B' THEN 'Good'
        WHEN 'C' THEN 'Average'
        WHEN 'D' THEN 'Needs Improvement'
        ELSE          'Unrated'
    END AS rating_label,
    p.bonus
FROM performance p
JOIN employees e ON e.emp_id = p.emp_id;
```

## Interview Tips

1. **CASE for pivoting**: "Show me orders per customer broken down by status in one query." The answer is `SUM(CASE WHEN status='X' THEN 1 ELSE 0 END)`. This pattern appears constantly in BI/data-engineering interviews.
2. **Simple vs Searched CASE**: Simple CASE only does equality checks; searched CASE handles ranges, NULLs, and complex conditions. Always use searched CASE when you have `>`, `<`, `IS NULL`, or multi-column conditions.
3. **ELSE NULL (default)**: Forgetting `ELSE 0` inside `SUM(CASE ...)` is fine — `NULL` values are ignored by `SUM`. But inside a `COUNT` it matters: `COUNT(CASE WHEN ... THEN 1 ELSE NULL END)` only counts matching rows. This is equivalent to `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`.
4. **Type consistency**: If one branch returns an integer and another returns a string, you'll get a type error. Interviewers may show you broken CASE code and ask you to spot the bug.
5. **CASE in ORDER BY for custom sort order**: Very common for dashboards — e.g., sort statuses as Pending → Shipped → Delivered → Cancelled regardless of alphabetical order.

## ❓ Practice Questions

1. Write a query that displays each employee's `name`, `salary`, and a new column `salary_grade` that shows `'Grade A'` for salary ≥ 90000, `'Grade B'` for 75000–89999, `'Grade C'` for 60000–74999, and `'Grade D'` for anything below.
```sql
SELECT 
    name, 
    salary,
    CASE
        WHEN salary >= 90000 THEN 'Grade A'
        WHEN salary BETWEEN 75000 AND 89999 THEN 'Grade B'
        WHEN salary BETWEEN 60000 AND 74999 THEN 'Grade C'
        ELSE 'Grade D'
    END AS salary_grade
FROM employees;
```

3. Using conditional aggregation with `CASE`, write a single query that shows — for each `dept_id` — the **total salary paid** to employees in the `'High'` band (≥ 90000) and the **total salary paid** to employees in the `'Low'` band (< 75000).
```sql
SELECT 
    dept_id,
    SUM(
        CASE
            WHEN salary >= 90000 THEN salary
            ELSE 0
        END
    ) AS high_salary_total,
    SUM(
        CASE
            WHEN salary < 75000 THEN salary
            ELSE 0
        END
    ) AS low_salary_total
FROM employees
GROUP BY dept_id
```


5. Write a query that retrieves all orders and adds a column `priority` that is `'Urgent'` if `status = 'Pending'` and `amount > 1000`, `'Normal'` if `status = 'Pending'` and `amount <= 1000`, and `'Closed'` for all other statuses.
```sql
SELECT 
     order_id,
    CASE
        WHEN status = 'Pending' AND amount > 1000 THEN 'Urgent'
        WHEN status = 'Pending' AND amount <=1000 THEN 'Normal'
        ELSE 'Closed'
    END AS priority
FROM orders
 
```

7. Using a `CASE` in `ORDER BY`, sort the `products` table so that `'Electronics'` appears first, `'Clothing'` second, `'Food'` third, and all other categories last. Within each category, sort by `price` descending.
```sql
SELECT 
    order_id
FROM products
ORDER BY
    CASE
        WHEN category = 'Electronics' THEN 1
        WHEN category = 'Clothing' THEN 2
        WHEN category =  'Food' THEN 3
        ELSE 4
    END , price DESC
```

9. Write an `UPDATE` statement using `CASE` that raises the `bonus` in the `performance` table by 20% for employees with `rating = 'A'`, by 10% for `rating = 'B'`, and leaves the bonus unchanged for all other ratings.
```sql
UPDATE performance
SET bonus = bonus * CASE
    WHEN rating = 'A' THEN 1.2
    WHEN rating = 'B' THEN 1.1
    ELSE 1
END;
```
