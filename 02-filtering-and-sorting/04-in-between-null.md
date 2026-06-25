# IN, BETWEEN, IS NULL — Filtering Ranges, Lists, and Missing Data

> **Interview Priority**: 🔴 Must Know

## What Is It?

`IN`, `BETWEEN`, and `IS NULL` are shorthand filtering operators that make `WHERE` clauses cleaner and more readable. They cover the three most common real-world filtering patterns: matching against a **list of values**, filtering within a **range**, and handling **missing data**. The NULL trap with `NOT IN` is one of the most tested interview topics in SQL.

## Syntax

```sql
-- IN
WHERE column IN (value1, value2, value3)
WHERE column IN (SELECT col FROM other_table)   -- subquery form

-- NOT IN
WHERE column NOT IN (value1, value2, ...)
WHERE column NOT IN (SELECT col FROM other_table)

-- BETWEEN (inclusive on both ends)
WHERE column BETWEEN low_value AND high_value

-- NOT BETWEEN
WHERE column NOT BETWEEN low_value AND high_value

-- IS NULL / IS NOT NULL
WHERE column IS NULL
WHERE column IS NOT NULL
```

## Key Concepts

### IN
- Equivalent to `col = v1 OR col = v2 OR col = v3`.
- Works on numbers, strings, and dates.
- The subquery form `IN (SELECT ...)` is a **correlated or non-correlated subquery** depending on whether the subquery references the outer query.
- **Performance**: For large lists, `IN` with a subquery is often rewritten by the optimizer as a semi-join; for small literal lists it's fine.

### BETWEEN
- **Both endpoints are inclusive**: `BETWEEN 60000 AND 85000` includes exactly 60000 and 85000.
- Works on numbers, dates, and strings (lexicographic ordering for strings).
- `NOT BETWEEN` excludes the entire range including endpoints.

### IS NULL / IS NOT NULL
- `NULL` is not a value — it represents the *absence* of a value.
- You **cannot** use `= NULL` or `!= NULL`; these always evaluate to `NULL` (unknown), not `TRUE` or `FALSE`. Always use `IS NULL` / `IS NOT NULL`.
- Aggregates (except `COUNT(*)`) ignore NULLs automatically.

### ⚠️ The NOT IN + NULL Trap (Critical Interview Topic)

This is one of the most dangerous and commonly tested SQL traps.

**Setup**: Suppose you want employees who are NOT managers of any other employee.

```sql
-- manager_id column has some NULL values (top-level employees)
SELECT name
FROM employees
WHERE emp_id NOT IN (SELECT manager_id FROM employees);
```

**If the subquery returns even one `NULL`** (which it will, since some employees have no manager, so `manager_id` IS NULL for them), the entire `NOT IN` condition evaluates to `NULL` for every row — resulting in **zero rows returned**, even when you'd expect results.

**Why?** SQL uses three-valued logic. When comparing `emp_id NOT IN (1, 2, NULL)`:
```
emp_id = 5:
  5 <> 1 → TRUE
  5 <> 2 → TRUE
  5 <> NULL → NULL (unknown)
  TRUE AND TRUE AND NULL → NULL  ← not TRUE, so row excluded
```

**Fix 1**: Use `NOT EXISTS` instead

```sql
SELECT name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM employees m WHERE m.manager_id = e.emp_id
);
```

**Fix 2**: Filter NULLs out of the subquery

```sql
SELECT name
FROM employees
WHERE emp_id NOT IN (
    SELECT manager_id FROM employees WHERE manager_id IS NOT NULL
);
```

## Examples

### 1 — IN with a literal list (specific departments)

```sql
SELECT name, dept_id, salary
FROM employees
WHERE dept_id IN (10, 30);

-- Returns: Aman (Eng, 85000), Dev (Eng, 78000), Ravi (Finance, 91000)
```

### 2 — NOT IN with a literal list

```sql
SELECT name, dept_id
FROM employees
WHERE dept_id NOT IN (10, 30);

-- Returns: Priya (HR, 20), Zara (Marketing, 40)
```

### 3 — IN with a subquery (employees in departments located in 'Mumbai')

```sql
SELECT name, salary
FROM employees
WHERE dept_id IN (
    SELECT dept_id
    FROM departments
    WHERE location = 'Mumbai'
);
```

### 4 — BETWEEN for salary range (inclusive)

```sql
SELECT name, salary
FROM employees
WHERE salary BETWEEN 70000 AND 90000;

-- Returns: Dev (78000), Zara (74000), Aman (85000)
-- 70000 and 90000 themselves would also match if present
```

### 5 — NOT BETWEEN

```sql
SELECT name, salary
FROM employees
WHERE salary NOT BETWEEN 70000 AND 90000;

-- Returns: Priya (62000), Ravi (91000)
```

### 6 — BETWEEN with dates

```sql
SELECT order_id, order_date, amount
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- All orders placed in the year 2024
```

### 7 — IS NULL (employees with no manager)

```sql
SELECT name, manager_id
FROM employees
WHERE manager_id IS NULL;

-- Returns: top-level managers (no manager above them)
```

### 8 — IS NOT NULL (employees who do have a manager)

```sql
SELECT name, manager_id
FROM employees
WHERE manager_id IS NOT NULL;
```

### 9 — Wrong way to check NULL — NEVER do this

```sql
-- This returns NO rows — the comparison always yields NULL, never TRUE
SELECT name FROM employees WHERE manager_id = NULL;    -- ❌ WRONG

-- Correct:
SELECT name FROM employees WHERE manager_id IS NULL;   -- ✅ CORRECT
```

### 10 — The NOT IN NULL trap in action

```sql
-- Suppose employees table manager_id column contains: 1, 2, NULL

-- This returns ZERO rows because of the NULL in the subquery:
SELECT name
FROM employees
WHERE emp_id NOT IN (SELECT manager_id FROM employees);   -- ❌ Dangerous

-- Fix: exclude NULLs from subquery
SELECT name
FROM employees
WHERE emp_id NOT IN (
    SELECT manager_id FROM employees WHERE manager_id IS NOT NULL
);  -- ✅ Safe

-- Or use NOT EXISTS:
SELECT e.name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM employees m WHERE m.manager_id = e.emp_id
);  -- ✅ Also safe, and often more efficient
```

### 11 — Combining IN, BETWEEN, and IS NOT NULL

```sql
SELECT name, dept_id, salary, manager_id
FROM employees
WHERE dept_id IN (10, 20)
  AND salary BETWEEN 60000 AND 90000
  AND manager_id IS NOT NULL;
```

### 12 — IN with strings (product categories)

```sql
SELECT product_name, category, price
FROM products
WHERE category IN ('Electronics', 'Clothing');
```

### 13 — Customers with no email on record

```sql
SELECT customer_id, name
FROM customers
WHERE email IS NULL;
```

## Operator Comparison Table

| Operator | What it tests | NULL safe? | Equivalent long form |
|---|---|---|---|
| `IN (list)` | Equality to any value in list | No | `= v1 OR = v2 OR ...` |
| `NOT IN (list)` | Not equal to any; **breaks on NULL** | **No** | `<> v1 AND <> v2 AND ...` |
| `BETWEEN a AND b` | Inclusive range | No | `>= a AND <= b` |
| `NOT BETWEEN a AND b` | Outside range | No | `< a OR > b` |
| `IS NULL` | Value is missing | **Yes** | *(no equivalent with `=`)* |
| `IS NOT NULL` | Value is present | **Yes** | *(no equivalent with `<>`)* |
| `NOT EXISTS (sub)` | Subquery returns no rows | **Yes** | Safe alternative to NOT IN |

## Interview Tips

1. **The #1 interview trap**: `NOT IN` returns empty results when the subquery contains a `NULL`. Always remember: fix by filtering NULLs in the subquery or switching to `NOT EXISTS`. Interviewers love asking "why does this query return no rows?"
2. **`= NULL` vs `IS NULL`**: Using `= NULL` is always wrong in standard SQL — it evaluates to `NULL`, not `TRUE`. This is among the top 5 beginner SQL mistakes.
3. **`BETWEEN` is inclusive** on both ends. Interviewers occasionally ask whether the boundary values are included — they are. Date ranges: `BETWEEN '2024-01-01' AND '2024-12-31'` misses times after midnight on Dec 31 in datetime columns; use `< '2025-01-01'` instead for safety.
4. **`IN` vs `EXISTS` for subqueries**: For large datasets, `EXISTS` short-circuits on the first match and is often faster. `IN` evaluates the entire subquery first. The optimizer often makes them equivalent, but understanding the difference shows depth.
5. **Three-valued logic**: SQL has TRUE, FALSE, and **UNKNOWN** (NULL). Any comparison with NULL yields UNKNOWN. WHERE clauses only pass rows where the condition is TRUE — UNKNOWN rows are silently excluded. This explains many surprising query results.

## ❓ Practice Questions

1. Write a query to find all employees whose `dept_id` is in the Engineering (10), Finance (30), or Marketing (40) departments using `IN`. Then rewrite it without `IN` using only `OR`.

2. Find all orders where the `amount` is between **500 and 2000** (inclusive) and the `status` is either `'Shipped'` or `'Delivered'`. Use both `BETWEEN` and `IN`.

3. Find all employees who do **not** report to any manager (i.e., `manager_id` is NULL). Then write the opposite — find employees who do have a manager assigned.

4. You want employees whose `emp_id` is NOT IN the list of `manager_id`s from the same `employees` table. Write this query two ways: once with `NOT IN` (with the NULL-safe fix), and once with `NOT EXISTS`. Explain why they can differ.

5. List all customers who have **not placed any order** — i.e., their `customer_id` does not appear in the `orders` table. Use `NOT IN` with the NULL-safe pattern and also write a `NOT EXISTS` version.
