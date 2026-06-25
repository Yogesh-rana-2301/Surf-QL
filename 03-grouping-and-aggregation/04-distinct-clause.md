# SELECT DISTINCT — Eliminating Duplicate Rows

> **Interview Priority**: 🟡 Important

## What Is It?

`SELECT DISTINCT` removes duplicate rows from the result set. When applied to multiple columns, it returns rows where the **combination** of all selected columns is unique — not just any single column. It is commonly used to answer questions like "how many unique customers have ordered?" or "which unique cities are our customers from?"

## Syntax

```sql
-- Distinct on a single column
SELECT DISTINCT column1
FROM table_name;

-- Distinct on multiple columns (unique combination)
SELECT DISTINCT column1, column2
FROM table_name;

-- DISTINCT inside an aggregate
SELECT COUNT(DISTINCT column1)
FROM table_name;
```

## Key Concepts

### DISTINCT Applies to the Entire Row

`DISTINCT` is not a function — it applies to **all selected columns together**. You cannot selectively deduplicate only one column when selecting multiple.

```sql
-- This removes rows where (city, dept_id) COMBINATION is duplicate
-- NOT just where city is duplicate
SELECT DISTINCT city, dept_id FROM employees;
```

### DISTINCT vs GROUP BY

Both can produce unique values, but they work differently:

| Feature | DISTINCT | GROUP BY |
|---|---|---|
| Primary purpose | Remove duplicate rows | Group rows for aggregation |
| Use with aggregates | Only in aggregate arguments (`COUNT(DISTINCT col)`) | Yes, fully supports aggregates |
| NULLs | One NULL is kept (NULLs are "equal" for dedup) | NULLs grouped together (same) |
| Output ordering | Not guaranteed (unless ORDER BY added) | Not guaranteed either |
| Performance | Often similar; optimizer may treat them the same | Sometimes has a slight edge with indexes |
| Readability | Clearer for "give me unique values" intent | Clearer when aggregation is needed |

**Rule of thumb**: Use `DISTINCT` when you just want unique rows, no aggregation. Use `GROUP BY` when you want per-group summaries.

### COUNT(DISTINCT col) — The Most Important DISTINCT Use Case

```sql
-- How many unique customers have placed orders?
SELECT COUNT(DISTINCT customer_id) FROM orders;

-- This is fundamentally different from:
SELECT COUNT(customer_id) FROM orders;     -- counts every order row
SELECT COUNT(*) FROM orders;               -- counts every row including NULLs
```

### DISTINCT with NULLs

`DISTINCT` treats all `NULL` values as equal — so multiple `NULL` rows collapse to a single `NULL` row in the result.

```sql
SELECT DISTINCT manager_id FROM employees;
-- If three employees have NULL manager_id, only one NULL appears in the result
```

### Performance Considerations

- `DISTINCT` forces a **sort or hash** operation to identify duplicates — it can be expensive on large tables.
- If you know the data has no duplicates (due to schema constraints), avoid `DISTINCT` — it adds unnecessary overhead.
- An index on the `DISTINCT` column(s) can significantly speed things up.
- In many databases, `SELECT DISTINCT col FROM t` and `SELECT col FROM t GROUP BY col` produce identical query plans.

### DISTINCT in Subqueries

Using `DISTINCT` inside subqueries is often unnecessary because the outer query's join or filter may already guarantee uniqueness — and it adds cost.

## Examples

### 1 — Unique department IDs in the employees table

```sql
SELECT DISTINCT dept_id
FROM employees;

-- Result: 10, 20, 30, 40
-- (No duplicates — each dept_id appears only once even though Engineering has 2 employees)
```

### 2 — Unique cities customers come from

```sql
SELECT DISTINCT city
FROM customers
ORDER BY city;
```

### 3 — DISTINCT on multiple columns (unique dept + salary combinations)

```sql
SELECT DISTINCT dept_id, salary
FROM employees
ORDER BY dept_id;

-- Returns one row per unique (dept_id, salary) pair
-- dept_id=10 has two different salaries (85000, 78000) → two rows for dept 10
```

### 4 — DISTINCT vs no DISTINCT — see the difference

```sql
-- Without DISTINCT: every order row listed (customer may repeat)
SELECT customer_id FROM orders;
-- Returns: 1, 1, 2, 3, 2, 1, ... (many duplicates)

-- With DISTINCT: each customer_id appears once
SELECT DISTINCT customer_id FROM orders;
-- Returns: 1, 2, 3, ... (unique customers only)
```

### 5 — COUNT(DISTINCT) — unique customers with orders

```sql
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM orders;

-- Very different from:
SELECT COUNT(customer_id) AS total_order_rows FROM orders;
```

### 6 — COUNT(DISTINCT) per group — unique products per customer

```sql
SELECT customer_id,
       COUNT(order_id)             AS total_orders,
       COUNT(DISTINCT product_id)  AS unique_products
FROM orders
GROUP BY customer_id;
```

### 7 — DISTINCT with NULLs (only one NULL survives)

```sql
SELECT DISTINCT manager_id
FROM employees;

-- Even if 3 employees have NULL manager_id, result shows NULL once
-- Result: NULL, 1, 2, ...
```

### 8 — DISTINCT vs GROUP BY — same result, different intent

```sql
-- Both return the same unique dept_id values:
SELECT DISTINCT dept_id FROM employees;

SELECT dept_id FROM employees GROUP BY dept_id;

-- Functionally equivalent here; GROUP BY is preferred when you add aggregates
```

### 9 — When GROUP BY is strictly better (with aggregation)

```sql
-- ❌ DISTINCT cannot do this:
SELECT DISTINCT dept_id, COUNT(*) FROM employees;   -- Error or meaningless

-- ✅ GROUP BY is the right tool:
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id;
```

### 10 — Distinct product categories in the products table

```sql
SELECT DISTINCT category
FROM products
ORDER BY category;

-- Returns: Clothing, Electronics, Food
```

### 11 — Unique (status, year) combinations in orders

```sql
SELECT DISTINCT status, YEAR(order_date) AS order_year
FROM orders
ORDER BY order_year, status;
```

### 12 — Avoiding unnecessary DISTINCT (when data is already unique)

```sql
-- primary key is always unique — DISTINCT here is wasted effort
SELECT DISTINCT emp_id FROM employees;   -- emp_id is PK, no duplicates possible
-- Better:
SELECT emp_id FROM employees;
```

## DISTINCT vs GROUP BY Decision Table

| Scenario | Use |
|---|---|
| Just want unique column values | `DISTINCT` |
| Want unique values + count/sum/avg | `GROUP BY` + aggregate |
| Want unique count inside a bigger aggregate | `COUNT(DISTINCT col)` |
| Remove duplicates from a JOIN that produces extras | `DISTINCT` (or fix the JOIN) |
| Checking uniqueness of a column in debugging | `DISTINCT` |

## Interview Tips

1. **"What does DISTINCT on multiple columns do?"** — It deduplicates based on the *combination* of all listed columns, not each column independently. A very common misconception.
2. **`COUNT(DISTINCT col)` vs `COUNT(col)`**: `COUNT(DISTINCT col)` counts unique non-NULL values; `COUNT(col)` counts all non-NULL rows including duplicates. Interviewers love presenting a table and asking "what does each return?"
3. **DISTINCT and NULLs**: Multiple NULLs are treated as equal by `DISTINCT` and collapse to one row. `COUNT(DISTINCT col)` excludes NULLs entirely (since `COUNT` skips NULLs).
4. **Performance**: `SELECT DISTINCT col` and `SELECT col GROUP BY col` are often rewritten to the same plan by modern optimizers. But `GROUP BY` is semantically clearer when you want grouping/aggregation, and `DISTINCT` is clearer for deduplication intent.
5. **`COUNT(DISTINCT col) OVER (PARTITION BY ...)`** is **not supported** in standard SQL window functions. If an interviewer asks for distinct counts in a window, you need a workaround (subquery, CTE with `DENSE_RANK`, or a lateral join). This is a known limitation that senior candidates are expected to know.

## ❓ Practice Questions

1. Write a query to find all **unique cities** that customers in the `customers` table are from. Sort alphabetically.

2. How many **distinct products** have been ordered at least once? Use `COUNT(DISTINCT ...)` on the `orders` table.

3. For each `customer_id` in the `orders` table, compute the **number of distinct order statuses** that customer has had (e.g., a customer may have both 'Pending' and 'Delivered' orders). Show customer_id and the count.

4. Write both a `SELECT DISTINCT` version and a `GROUP BY` version that return the unique `(category, price)` combinations from the `products` table. Are the results identical? When would they differ?

5. From the `performance` table, find all distinct `(emp_id, year)` pairs where the employee received a rating of `'A'`. Explain why you might or might not need `DISTINCT` here depending on the data's constraints.
