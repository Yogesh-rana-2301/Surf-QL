# Window Functions — Analytics Without Collapsing Rows

> **Interview Priority**: 🔴 Must Know

## What Is It?

A **window function** performs a calculation across a set of rows that are related to the current row — its *window* — **without collapsing those rows into a single output row**. Unlike `GROUP BY` aggregates that reduce many rows to one, window functions return **one result per input row**, making them ideal for running totals, rankings, and row-to-row comparisons. They are the single most-tested advanced SQL topic in data/engineering interviews.

---

## Syntax

```sql
function_name(expression)
    OVER (
        [PARTITION BY partition_column, ...]
        [ORDER BY    sort_column [ASC|DESC], ...]
        [frame_clause]                          -- see the next file
    )
```

| Clause | Purpose |
|--------|---------|
| `PARTITION BY` | Divides rows into independent groups (like GROUP BY, but rows aren't collapsed) |
| `ORDER BY` (inside OVER) | Defines the logical ordering of rows within each partition |
| Frame clause | Defines which rows around the current row are included (defaults vary by function) |

All three clauses are **optional**, but omitting `ORDER BY` changes the default frame for aggregate window functions (see frame clause file).

---

## Key Concepts

### 1 · Window Functions Do Not Filter Rows

You **cannot** use a window function alias directly in `WHERE` or `HAVING` in the same `SELECT`. The window is evaluated after `WHERE` but before `ORDER BY`.

```sql
-- ❌ WRONG — cannot reference window alias in WHERE
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS rnk
FROM   employees
WHERE  rnk <= 3;   -- ERROR: rnk is not yet resolved here

-- ✅ CORRECT — wrap in a subquery or CTE
WITH ranked AS (
    SELECT name, salary,
           RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM   employees
)
SELECT * FROM ranked WHERE rnk <= 3;
```

### 2 · PARTITION BY vs GROUP BY

| | `GROUP BY` | `PARTITION BY` |
|--|-----------|---------------|
| Output rows | One per group | One per input row |
| Collapses rows? | Yes | No |
| Use case | Aggregate reporting | Per-row analytics |
| Access to non-aggregated columns | ❌ Only aggregated/grouped cols | ✅ All original columns |

### 3 · ORDER BY Inside OVER Is Different from Query-Level ORDER BY

`ORDER BY` inside `OVER()` defines the **logical ordering used by the window function** (for ranking, running totals, LAG/LEAD). It has no effect on the final sort order of query output — for that, use a query-level `ORDER BY` at the end.

---

## All Major Window Functions

### A · Ranking Functions

#### `ROW_NUMBER()` — Unique sequential integer, no ties

```sql
SELECT name,
       salary,
       dept_id,
       ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS row_num
FROM   employees;
```

Every row gets a unique number within its department even if two salaries are equal — one of the tied rows arbitrarily gets the lower number.

| name  | salary | dept_id | row_num |
|-------|--------|---------|---------|
| Ravi  | 91000  | 30      | 1       |
| Aman  | 85000  | 10      | 1       |
| Dev   | 78000  | 10      | 2       |
| Zara  | 74000  | 40      | 1       |
| Priya | 62000  | 20      | 1       |

---

#### `RANK()` — Leaves gaps after ties

```sql
SELECT name,
       salary,
       RANK() OVER (ORDER BY salary DESC) AS rnk
FROM   employees;
```

If two employees share rank 2, the next rank assigned is 4 (gap of 1 per tie). Used when gaps in ranking are meaningful (e.g., sports standings).

---

#### `DENSE_RANK()` — No gaps after ties

```sql
SELECT name,
       salary,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
FROM   employees;
```

If two employees share rank 2, the next rank is 3 (no gap). Use when you want "top N distinct salary levels."

---

#### `RANK()` vs `DENSE_RANK()` vs `ROW_NUMBER()` — Side by Side

| salary | ROW_NUMBER | RANK | DENSE_RANK |
|--------|-----------|------|-----------|
| 91000  | 1         | 1    | 1         |
| 85000  | 2         | 2    | 2         |
| 85000  | 3         | 2    | 2         |
| 78000  | 4         | 4    | 3         |
| 74000  | 5         | 5    | 4         |

---

#### `NTILE(n)` — Divide rows into N equal buckets

```sql
-- Divide employees into salary quartiles
SELECT name,
       salary,
       NTILE(4) OVER (ORDER BY salary DESC) AS salary_quartile
FROM   employees;
```

Employees in quartile 1 are the top 25% earners. Useful for percentile-based segmentation.

---

### B · Value (Navigation) Functions

#### `LAG(col, offset, default)` — Access a previous row's value

```sql
-- Compare each order's amount to the previous order by the same customer
SELECT order_id,
       customer_id,
       amount,
       order_date,
       LAG(amount, 1, 0) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
       ) AS prev_order_amount,
       amount - LAG(amount, 1, 0) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
       ) AS amount_change
FROM   orders;
```

- `offset = 1` means look 1 row back (default).
- `default = 0` is returned when there is no previous row (first row of partition).

---

#### `LEAD(col, offset, default)` — Access a next row's value

```sql
-- Show each order's amount and the next order amount for the same customer
SELECT order_id,
       customer_id,
       amount,
       order_date,
       LEAD(amount, 1, NULL) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
       ) AS next_order_amount
FROM   orders;
```

Useful for finding "what happens next" — churn prediction, next-day price comparison.

---

#### `FIRST_VALUE(col)` — First value in the window frame

```sql
-- Show each employee's salary alongside the highest salary in their department
SELECT name,
       dept_id,
       salary,
       FIRST_VALUE(salary) OVER (
           PARTITION BY dept_id
           ORDER BY salary DESC
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS dept_max_salary
FROM   employees;
```

> ⚠️ `FIRST_VALUE` and `LAST_VALUE` are frame-sensitive. Always specify the frame explicitly — the default frame often cuts off before the end of the partition (see frame clause file).

---

#### `LAST_VALUE(col)` — Last value in the window frame

```sql
-- Show each employee's salary alongside the lowest salary in their department
SELECT name,
       dept_id,
       salary,
       LAST_VALUE(salary) OVER (
           PARTITION BY dept_id
           ORDER BY salary DESC
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- required!
       ) AS dept_min_salary
FROM   employees;
```

---

### C · Aggregate Window Functions

These are standard aggregate functions (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`) given an `OVER()` clause — they aggregate without collapsing rows.

#### Running Total

```sql
-- Running total of order amounts, ordered by date
SELECT order_id,
       order_date,
       amount,
       SUM(amount) OVER (
           ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM   orders;
```

#### Partition Total (Each Row Sees Its Group's Total)

```sql
-- Show each order's amount AND total orders for that customer
SELECT order_id,
       customer_id,
       amount,
       SUM(amount) OVER (PARTITION BY customer_id) AS customer_total,
       amount / SUM(amount) OVER (PARTITION BY customer_id) * 100 AS pct_of_customer_total
FROM   orders;
```

#### Running Average

```sql
SELECT order_id,
       order_date,
       amount,
       AVG(amount) OVER (
           ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_avg
FROM   orders;
```

#### Count of Rows in Partition

```sql
-- How many employees are in each department (shown on every row)
SELECT name,
       dept_id,
       COUNT(*) OVER (PARTITION BY dept_id) AS dept_headcount
FROM   employees;
```

---

## Key Patterns

### Pattern 1 — Top N Per Group

```sql
-- Top 2 earners in each department
WITH ranked AS (
    SELECT name,
           dept_id,
           salary,
           DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk
    FROM   employees
)
SELECT name, dept_id, salary
FROM   ranked
WHERE  rnk <= 2;
```

### Pattern 2 — Latest Record Per Entity (Deduplication)

```sql
-- Most recent order per customer
WITH latest AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY order_date DESC
           ) AS rn
    FROM   orders
)
SELECT order_id, customer_id, amount, order_date
FROM   latest
WHERE  rn = 1;
```

`ROW_NUMBER()` guarantees exactly one row per partition — useful for deduplication where ties need a deterministic winner.

### Pattern 3 — Day-over-Day / Period-over-Period Comparison

```sql
-- For each order, what was the previous order's amount for the same customer?
SELECT order_id,
       customer_id,
       order_date,
       amount,
       LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_amount,
       ROUND(
           (amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date))
           / LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) * 100,
           2
       ) AS pct_change
FROM   orders;
```

### Pattern 4 — Percentile Ranking

```sql
-- Which salary quartile does each employee fall in (company-wide)?
SELECT name,
       salary,
       NTILE(100) OVER (ORDER BY salary) AS salary_percentile
FROM   employees;
```

---

## Common Mistakes

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Filtering on window alias in same SELECT | Window functions are evaluated after WHERE | Wrap in CTE or subquery |
| Using GROUP BY when window is needed | GROUP BY collapses rows; window functions don't | Use `OVER(PARTITION BY ...)` instead |
| Forgetting ORDER BY in OVER for ranking | ROW_NUMBER/RANK without ORDER BY in OVER is non-deterministic | Always specify ORDER BY inside OVER for ranking functions |
| LAST_VALUE returning unexpected results | Default frame (`RANGE UNBOUNDED PRECEDING`) doesn't extend to partition end | Add `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` |
| Confusing PARTITION BY and GROUP BY syntax | They look similar but serve different purposes | PARTITION BY is inside OVER(); GROUP BY is a standalone clause |

---

## Interview Tips

1. **Lead with the definition contrast.** "Window functions compute a value for each row using a set of related rows — unlike GROUP BY, they don't collapse the output." Saying this first anchors your answer.

2. **Know all three ranking functions cold.** `ROW_NUMBER` (unique), `RANK` (gaps on ties), `DENSE_RANK` (no gaps on ties). Be able to construct the side-by-side comparison table from memory.

3. **Top-N per group is the #1 asked window pattern.** Write a `ROW_NUMBER()` or `DENSE_RANK()` with `PARTITION BY` in a CTE, then filter with `WHERE rnk <= N`. Practice until it's automatic.

4. **`LAST_VALUE` frame trap.** This is a well-known gotcha: without an explicit frame extending to `UNBOUNDED FOLLOWING`, `LAST_VALUE` sees only up to the current row (default frame). Always mention this when discussing `FIRST_VALUE`/`LAST_VALUE`.

5. **Aggregate + OVER vs GROUP BY.** `SUM(amount) OVER (PARTITION BY customer_id)` gives every row access to its partition's total without collapsing rows. `GROUP BY customer_id` with `SUM(amount)` produces one row per customer. Interviewers frequently probe this distinction.

---

## ❓ Practice Questions

1. Write a query to rank all employees **within their department** by salary (highest first). Use `DENSE_RANK()`. Show name, department, salary, and rank.

2. Using `ROW_NUMBER()`, find the **most recent order** placed by each customer. Show customer_id, order_id, amount, and order_date.

3. For each order in the `orders` table, show the order amount along with a **running total of amounts** ordered by `order_date`. Include orders from all customers combined.

4. Use `LAG()` to compare each employee's **current year bonus to the previous year bonus** (from the `performance` table, partitioned by employee and ordered by year). Show the difference.

5. Write a query that shows each product's price alongside:
   - The **minimum price in its category**
   - The **maximum price in its category**
   - The product's **price rank within its category** (1 = most expensive)
