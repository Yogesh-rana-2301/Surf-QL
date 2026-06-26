# Operators — Filtering and Matching Data Precisely

> **Interview Priority**: 🔴 Must Know

## What Is It?

SQL operators extend the `WHERE` clause beyond simple equality checks. They let you match ranges (`BETWEEN`), lists (`IN`), patterns (`LIKE`), and null values (`IS NULL`). Their negations (`NOT IN`, `NOT BETWEEN`, `NOT LIKE`) are equally important — and carry some surprising edge cases that interviewers specifically probe.

## Syntax

```sql
-- Comparison operators
WHERE salary > 70000
WHERE salary >= 70000
WHERE salary < 70000
WHERE salary <= 70000
WHERE salary = 70000
WHERE salary != 70000    -- also written as <>

-- Range check (inclusive on both ends)
WHERE salary BETWEEN 60000 AND 90000

-- List membership
WHERE dept_id IN (10, 20, 30)

-- Pattern matching (case-insensitive in MySQL by default)
WHERE name LIKE 'A%'          -- starts with A
WHERE name LIKE '%a'          -- ends with a
WHERE name LIKE '%Kumar%'     -- contains Kumar
WHERE email LIKE '_____@%'    -- exactly 5 chars before @

-- NULL checks
WHERE manager_id IS NULL
WHERE dept_id IS NOT NULL

-- Negations
WHERE salary NOT BETWEEN 60000 AND 90000
WHERE dept_id NOT IN (10, 20)
WHERE name NOT LIKE 'A%'
```

## Key Concepts

- **`BETWEEN` is inclusive**: `BETWEEN 60000 AND 90000` includes both 60000 and 90000. It's equivalent to `>= 60000 AND <= 90000`.
- **`IN` is cleaner than multiple `OR`**: `dept_id IN (10, 20, 30)` is more readable than `dept_id = 10 OR dept_id = 20 OR dept_id = 30`, and may be optimized differently by the query planner.
- **`LIKE` wildcards**: `%` matches zero or more characters. `_` matches exactly one character. These are the only two wildcards in standard SQL LIKE.
- **`NOT IN` with NULLs is a trap**: `dept_id NOT IN (10, NULL)` returns no rows — because any comparison with NULL returns NULL (unknown), and the database cannot confirm "not in the list" when NULL is present.
- **`IS NULL` vs `= NULL`**: `= NULL` always evaluates to NULL (never TRUE). Always use `IS NULL`.
- **Pattern matching performance**: `LIKE '%text%'` (leading wildcard) cannot use a B-tree index and forces a full table scan. `LIKE 'text%'` (prefix match) can use an index.
- **`BETWEEN` with dates**: Works naturally on `DATE` columns — `order_date BETWEEN '2024-01-01' AND '2024-03-31'` retrieves Q1 orders.

## Examples

```sql
-- 1. Comparison operators on salary
SELECT name, salary FROM employees WHERE salary > 80000;
-- Returns: Arjun (120000), Ravi (91000), Aman (85000), Karan (82000)

SELECT name, salary FROM employees WHERE salary != 120000;
-- Returns everyone except Arjun
```

```sql
-- 2. BETWEEN (inclusive range)
SELECT name, salary
FROM employees
WHERE salary BETWEEN 65000 AND 90000;
-- Returns: Aman (85000), Zara (74000), Dev (78000), Rahul (67000), Karan (82000), Sneha (69000)
-- Equivalent to: WHERE salary >= 65000 AND salary <= 90000
```

```sql
-- 3. NOT BETWEEN
SELECT name, salary
FROM employees
WHERE salary NOT BETWEEN 65000 AND 90000;
-- Returns: Arjun (120000), Priya (62000), Ravi (91000), Neha (55000), Meera (58000), Aditya (61000)
```

```sql
-- 4. BETWEEN on dates — Q1 2024 orders
SELECT order_id, order_date, amount
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';
-- Returns orders 1–9 (placed Jan–Mar 2024)
```

```sql
-- 5. IN operator — multiple departments
SELECT name, dept_id
FROM employees
WHERE dept_id IN (20, 30);
-- Returns: Priya (HR), Neha (HR), Ravi (Finance), Rahul (Finance)

-- Equivalent (less readable):
SELECT name, dept_id
FROM employees
WHERE dept_id = 20 OR dept_id = 30;
```

```sql
-- 6. NOT IN
SELECT name, dept_id
FROM employees
WHERE dept_id NOT IN (10, 40);
-- Returns HR and Finance employees (dept_id 20 and 30)
-- ⚠️ Does NOT return employees with dept_id IS NULL (Meera, Aditya)
```

```sql
-- 7. The NOT IN NULL trap — a critical interview question
SELECT name FROM employees
WHERE dept_id NOT IN (10, NULL);
-- Returns ZERO rows, even though many employees have non-NULL dept_id.
-- Why: 10 NOT IN (10, NULL) → FALSE; 20 NOT IN (10, NULL) → NULL (unknown); never TRUE.

-- Fix: ensure the list contains no NULLs, or use NOT EXISTS:
SELECT name FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM (SELECT 10 AS d UNION ALL SELECT NULL) AS exclusions
    WHERE e.dept_id = exclusions.d
);
-- OR simply exclude the NULL from the list if you know it's there:
SELECT name FROM employees WHERE dept_id NOT IN (10) AND dept_id IS NOT NULL;
```

```sql
-- 8. LIKE — pattern matching on names
SELECT name FROM employees WHERE name LIKE 'A%';
-- Starts with 'A': Arjun, Aman, Aditya

SELECT name FROM employees WHERE name LIKE '%Kumar%';
-- Contains 'Kumar': Ravi Kumar

SELECT name FROM employees WHERE name LIKE '____% %';
-- Any name with at least 4 chars in first word

SELECT email FROM employees WHERE email LIKE '%@company.com';
-- All company email addresses
```

```sql
-- 9. NOT LIKE
SELECT name, email
FROM customers
WHERE email NOT LIKE '%gmail.com';
-- Returns customers whose email doesn't end in gmail.com (none in our data — 0 rows)
```

```sql
-- 10. IS NULL and IS NOT NULL
SELECT name, dept_id FROM employees WHERE dept_id IS NULL;
-- Returns: Meera Joshi, Aditya Roy

SELECT name, manager_id FROM employees WHERE manager_id IS NOT NULL;
-- Returns everyone except Arjun Mehta (CEO, no manager)
```

```sql
-- 11. Combining operators
SELECT name, salary, dept_id
FROM employees
WHERE dept_id IN (10, 30)
  AND salary BETWEEN 75000 AND 100000
  AND name LIKE '%a%';
-- dept_id 10 or 30, salary in range, name contains 'a' (case-insensitive)
```

## Interview Tips

1. **`NOT IN` with NULL in the list returns 0 rows**: This is one of the most famous SQL gotchas. If the subquery used in `NOT IN` can return NULLs (e.g., `WHERE dept_id NOT IN (SELECT dept_id FROM employees)`), you get no results. The fix: use `NOT EXISTS` or add `WHERE dept_id IS NOT NULL` to the subquery.

2. **`BETWEEN` is always inclusive**: Both endpoints are included. `BETWEEN 1 AND 10` includes 1 and 10. If you need exclusive bounds, use `> lower AND < upper`.

3. **`LIKE '%text%'` is slow**: A leading `%` prevents B-tree index usage. For full-text search on production systems, use `FULLTEXT INDEX` (MySQL) or `tsvector` (PostgreSQL) instead of `LIKE`.

4. **`IN` vs `EXISTS` for subqueries**: For large datasets, `NOT EXISTS` generally outperforms `NOT IN` because it short-circuits on the first match and handles NULLs correctly. Prefer `NOT EXISTS` when the subquery could return NULLs.

5. **`<>` and `!=` are equivalent**: Both mean "not equal". `<>` is the ANSI SQL standard; `!=` is widely supported shorthand. Interviewers may use either — both are valid.

## ❓ Practice Questions

1. Write a query to find all employees with a salary between ₹70,000 and ₹95,000 (inclusive) who work in either Engineering or Finance. Use `BETWEEN` and `IN` together.
```sql
SELECT name, salary
FROM employees
WHERE salary  BETWEEN 70000 AND 95000 AND department IN ('Engineering', 'Finance');

```

3. From the `products` table, find all products whose `product_name` contains the word `'Pro'` or starts with `'C'`. Use `LIKE` and `OR`.
```sql
SELECT name
FROM products
WHERE NAME LIKE = '%Pro%' OR NAME LIKE = 'C%';


```

5. Find all customers whose `email` ends with `'@gmail.com'` and whose `city` is NOT in `('Mumbai', 'Delhi')`. Use `LIKE` and `NOT IN`.
```sql
SELECT name
FROM customers
WHERE email LIKE '%@gmail.com' AND city NOT IN ('Mumbai', 'Delhi');


```
6. Explain what happens when you run: `SELECT name FROM employees WHERE dept_id NOT IN (10, 20, NULL);`. Why does this return 0 rows? Write a corrected version using `NOT EXISTS` or with an explicit NULL guard.

7. Write a query to retrieve all orders placed in Q1 2024 (January 1 to March 31) with a status of either `'pending'` or `'completed'`. Use `BETWEEN` for the date range and `IN` for the status. Return `order_id`, `amount`, `order_date`, `status`.
