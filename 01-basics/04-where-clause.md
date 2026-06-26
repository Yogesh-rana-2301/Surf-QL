# WHERE Clause — Filtering Rows with Precision

> **Interview Priority**: 🔴 Must Know

## What Is It?

The `WHERE` clause filters rows **before** any grouping or aggregation happens. Only rows that satisfy the condition are included in the result. It works with `SELECT`, `UPDATE`, and `DELETE` — so understanding it correctly is critical for not accidentally modifying the wrong data.

## Syntax

```sql
SELECT column1, column2
FROM table_name
WHERE condition;

-- Multiple conditions
WHERE condition1 AND condition2
WHERE condition1 OR condition2
WHERE NOT condition1

-- NULL checks (always use IS NULL, never = NULL)
WHERE column IS NULL
WHERE column IS NOT NULL
```

## Key Concepts

- **Logical processing order**: `FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`. WHERE runs before SELECT, so you **cannot** reference SELECT aliases in WHERE.
- **`AND` has higher precedence than `OR`**: `WHERE a OR b AND c` is evaluated as `WHERE a OR (b AND c)`. Always use parentheses to make intent explicit.
- **`NULL` is not a value — it is unknown**: Any comparison with NULL using `=`, `!=`, `<`, `>` returns `NULL` (not TRUE or FALSE). Use `IS NULL` or `IS NOT NULL` to test for NULL.
- **`NOT` negates a condition**: `WHERE NOT salary > 70000` is equivalent to `WHERE salary <= 70000`, but the explicit form is clearer.
- **Avoid functions on indexed columns in WHERE**: `WHERE YEAR(hire_date) = 2020` prevents index usage. Prefer range comparisons: `WHERE hire_date BETWEEN '2020-01-01' AND '2020-12-31'`.

## Examples

```sql
-- 1. Simple equality filter
SELECT name, salary
FROM employees
WHERE dept_id = 10;
-- Returns: Arjun, Aman, Dev, Karan (all Engineering employees)
```

```sql
-- 2. Comparison operators
SELECT name, salary
FROM employees
WHERE salary > 80000;
-- Returns: Arjun (120000), Ravi (91000), Aman (85000), Karan (82000)
```

```sql
-- 3. AND operator — both conditions must be true
SELECT name, salary, dept_id
FROM employees
WHERE dept_id = 10 AND salary > 80000;
-- Returns: Arjun (120000), Aman (85000), Karan (82000)
```

```sql
-- 4. OR operator — at least one condition must be true
SELECT name, dept_id
FROM employees
WHERE dept_id = 20 OR dept_id = 30;
-- Returns: Priya (HR), Neha (HR), Ravi (Finance), Rahul (Finance)
```

```sql
-- 5. Operator precedence trap — AND binds tighter than OR
SELECT name, dept_id, salary
FROM employees
WHERE dept_id = 10 OR dept_id = 20 AND salary > 70000;
-- Interpreted as: dept_id=10 OR (dept_id=20 AND salary>70000)
-- Priya earns 62000 (HR) — NOT returned because of AND precedence
-- Fix with explicit parentheses:
SELECT name, dept_id, salary
FROM employees
WHERE (dept_id = 10 OR dept_id = 20) AND salary > 70000;
-- Now both conditions apply to the OR result
```

```sql
-- 6. NOT operator
SELECT name, dept_id
FROM employees
WHERE NOT dept_id = 10;
-- Returns all non-Engineering employees (AND excludes NULLs — see note below)
```

```sql
-- 7. NULL handling — IS NULL
SELECT name, dept_id
FROM employees
WHERE dept_id IS NULL;
-- Returns: Meera Joshi, Aditya Roy (no dept assigned)

-- WRONG approach — returns no rows because NULL = NULL is NULL, not TRUE
SELECT name FROM employees WHERE dept_id = NULL;  -- ❌ Never do this
```

```sql
-- 8. IS NOT NULL
SELECT name, email
FROM employees
WHERE manager_id IS NOT NULL;
-- Excludes Arjun Mehta (CEO with NULL manager_id)
```

```sql
-- 9. String filtering with inequality
SELECT name, email
FROM customers
WHERE city != 'Mumbai';
-- Returns all non-Mumbai customers
```

```sql
-- 10. Filter on computed expression (no alias, must repeat expression)
SELECT name, salary, salary * 0.10 AS bonus_estimate
FROM employees
WHERE salary * 0.10 > 8000;
-- Cannot write: WHERE bonus_estimate > 8000  ← alias not available in WHERE
```

```sql
-- 11. Date comparison
SELECT name, hire_date
FROM employees
WHERE hire_date >= '2022-01-01';
-- Returns employees hired in 2022 or later: Neha, Sneha, Meera, Aditya
```

## Interview Tips

1. **Why can't you use SELECT aliases in WHERE?** SQL's logical processing order evaluates `WHERE` before `SELECT`. The alias doesn't exist yet at WHERE-evaluation time. Use the full expression again in WHERE, or wrap in a subquery/CTE.

2. **`NULL` comparisons are a classic trap**: `WHERE manager_id = NULL` always returns 0 rows — because `NULL = NULL` evaluates to `NULL` (unknown), not `TRUE`. Always use `IS NULL` or `IS NOT NULL`. Interviewers love this one.

3. **`AND` precedence over `OR`**: `WHERE a OR b AND c` means `WHERE a OR (b AND c)`. This is one of the most common bugs in SQL filters. Always add parentheses when mixing `AND` and `OR`.

4. **`NOT IN` with NULLs is dangerous**: `WHERE dept_id NOT IN (10, NULL)` returns no rows, because `NOT IN` with a NULL in the list evaluates the entire condition as NULL. Covered more in operators notes.

5. **Index-friendliness matters**: `WHERE UPPER(name) = 'AMAN SHARMA'` cannot use an index on `name`. Prefer storing data in consistent case and filtering without functions, or use a function-based index.

## ❓ Practice Questions

1. Write a query to find all employees in the Finance department (`dept_id = 30`) with a salary above ₹65,000. Return their `name`, `salary`, and `hire_date`.
```sql
SELECT name, salary, hire_date
FROM employees
WHERE dept_id = 30
  AND salary > 65000;
```

3. Find all customers who are **not** from Mumbai or Delhi. Use the `customers` table. Write two versions: one using `!=` with `AND`, and one using `NOT IN`.
```sql
SELECT name
FROM customers
WHERE state NOT IN ('Mumbai', 'Delhi');
```
or 
```sql
SELECT name
FROM customers
WHERE state <> 'Mumbai'
  AND state <> 'Delhi';
```

5. Write a query to find employees with no manager assigned (`manager_id IS NULL`) OR employees with no department assigned (`dept_id IS NULL`). How many such employees exist in the dataset?
```sql
SELECT name
FROM employees
WHERE manager_id IS NULL
   OR dept_id IS NULL;
```

7. From the `orders` table, retrieve all orders where the `status` is `'pending'` and the `amount` is greater than ₹5,000. Return `order_id`, `amount`, and `order_date`.
```sql
SELECT order_id , amount, order_date
FROM orders
WHERE status = 'pending' AND amount > 5000;
```


9. A developer writes: `SELECT name FROM employees WHERE dept_id = NULL;` and gets 0 rows. They're confused — they know some employees have no department. Explain what's wrong and write the corrected query.
```md
because he is using null and dept_id=NULL is unknown, use IS```
