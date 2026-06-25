# Window Frame Clause — Precise Control Over the Window

> **Interview Priority**: 🟡 Important

## What Is It?

The **frame clause** is the optional third component of the `OVER()` clause. It defines **which subset of rows within the current partition** a window function should look at — the "frame" within the "window." While `PARTITION BY` groups rows and `ORDER BY` orders them, the frame clause specifies the **start and end boundaries** of the moving sub-range that each row's calculation is based on.

Understanding frame clauses is what separates intermediate SQL knowledge from advanced — and it is asked in senior engineering and data engineering rounds.

---

## Syntax

```sql
function_name(col) OVER (
    [PARTITION BY ...]
    [ORDER BY ...]
    { ROWS | RANGE | GROUPS }
      BETWEEN frame_start AND frame_end
)
```

### Frame Boundary Keywords

| Keyword | Meaning |
|---------|---------|
| `UNBOUNDED PRECEDING` | From the very first row of the partition |
| `N PRECEDING` | N rows/range-units before the current row |
| `CURRENT ROW` | The current row itself |
| `N FOLLOWING` | N rows/range-units after the current row |
| `UNBOUNDED FOLLOWING` | Up to the very last row of the partition |

### Valid Boundary Combinations

```
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW   ← default when ORDER BY is present
BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
BETWEEN N PRECEDING AND CURRENT ROW
BETWEEN N PRECEDING AND N FOLLOWING
BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
```

---

## Key Concepts

### 1 · Default Frame Behaviour

This is a major source of bugs — the default frame **changes based on whether ORDER BY is present**:

| Condition | Default Frame |
|-----------|--------------|
| `OVER()` — no ORDER BY, no frame | `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` (entire partition) |
| `OVER(ORDER BY col)` — ORDER BY, no explicit frame | `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` |

The second case is the dangerous one: when you write `SUM(amount) OVER (ORDER BY order_date)` without an explicit frame, you get a **running total** — not a full-partition total. If you wanted the full partition total, you must omit `ORDER BY` or use an explicit full frame.

### 2 · ROWS Mode — Physical Row Offsets

`ROWS` counts **actual rows** before/after the current row. Precise and predictable. Two rows with identical `ORDER BY` values are treated independently.

```sql
-- 3-row moving average (current + 2 preceding)
AVG(amount) OVER (
    ORDER BY order_date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
)
```

### 3 · RANGE Mode — Logical Value Offsets

`RANGE` groups rows with **identical ORDER BY values** as if they were a single logical unit. When multiple rows have the same sort key value, `RANGE BETWEEN ... AND CURRENT ROW` includes **all rows with the same key value as the current row** — not just the ones physically before it.

```sql
-- RANGE includes all rows with same order_date as current row
SUM(amount) OVER (
    ORDER BY order_date
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

This means a row whose `order_date = '2024-03-15'` will include **all rows with that same date** in the frame — even those that appear later in the physical ordering.

### 4 · GROUPS Mode (PostgreSQL 11+, SQL:2011 standard)

`GROUPS` is similar to `RANGE` but counts **groups of peer rows** (rows with the same ORDER BY value) rather than individual rows or value distances. Less commonly used; know it exists.

### 5 · ROWS vs RANGE — When They Differ

They differ **only when there are tied ORDER BY values**:
- `ROWS`: strict physical position — always predictable
- `RANGE`: treats peers (tied rows) as a unit — can include "future" peers of the current row

```
Given data ordered by date:
  date=Jan1, amount=100   ← row 1
  date=Jan1, amount=200   ← row 2 (same date as row 1 — peer)
  date=Jan2, amount=300   ← row 3

For row 1 (Jan1):
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW → SUM = 100
  RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW → SUM = 300 (includes row 2, same date)
```

---

## ROWS vs RANGE Comparison Table

| Feature | `ROWS` | `RANGE` |
|---------|--------|---------|
| Counts by | Physical row positions | Logical value distances |
| Handles ties | Each tied row counted separately | All peers included in frame |
| Predictability | ✅ Always deterministic | ⚠️ Depends on data distribution |
| Use case | Moving averages, exact N-row windows | Cumulative sums with date grouping |
| N PRECEDING/FOLLOWING with non-numeric ORDER BY | ❌ Not applicable | ✅ Can use INTERVAL for dates |
| Default mode | Not the default | Default when ORDER BY present |

---

## Examples

### Example 1 — Running Total of Order Amounts

```sql
-- Running total — each row accumulates all previous amounts
SELECT order_id,
       order_date,
       amount,
       SUM(amount) OVER (
           ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM   orders
ORDER  BY order_date;
```

| order_id | order_date | amount | running_total |
|----------|-----------|--------|---------------|
| 1        | 2024-01-01 | 500    | 500           |
| 2        | 2024-01-02 | 300    | 800           |
| 3        | 2024-01-03 | 700    | 1500          |
| 4        | 2024-01-04 | 200    | 1700          |

---

### Example 2 — 3-Day Moving Average of Order Amounts

```sql
-- Average of current row + 2 immediately preceding rows
SELECT order_id,
       order_date,
       amount,
       ROUND(
           AVG(amount) OVER (
               ORDER BY order_date
               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
           ), 2
       ) AS moving_avg_3day
FROM   orders
ORDER  BY order_date;
```

This is a **3-row sliding window**: the frame moves forward one row at a time. The first two rows have smaller frames (1-row, 2-row) because there aren't enough preceding rows.

---

### Example 3 — Cumulative Sum (RANGE vs ROWS Difference on Tied Dates)

```sql
-- Using ROWS — sums physical rows up to current
SELECT order_id, order_date, amount,
       SUM(amount) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rows_running_total
FROM   orders;

-- Using RANGE — all rows on the same date are grouped together
SELECT order_id, order_date, amount,
       SUM(amount) OVER (ORDER BY order_date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS range_running_total
FROM   orders;
```

**When orders have two rows on the same date (e.g., 2024-03-15):**

| order_id | order_date | amount | rows_running_total | range_running_total |
|----------|-----------|--------|--------------------|---------------------|
| 5        | 2024-03-15 | 400    | 2100               | 2500 ← includes peer|
| 6        | 2024-03-15 | 100    | 2200               | 2500 ← same value   |

With `RANGE`, both rows on `2024-03-15` report the same cumulative total because they are peers.

---

### Example 4 — Full Partition Sum (No Collapse) — Explicit Full Frame

```sql
-- Show each employee's salary and the total salary budget for their department
SELECT name,
       dept_id,
       salary,
       SUM(salary) OVER (
           PARTITION BY dept_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS dept_total_salary
FROM   employees;
```

Without specifying the full frame, adding `ORDER BY salary` would change this to a running total within the department — a subtle bug. The explicit `UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` ensures every row sees the full partition's sum.

---

### Example 5 — FIRST_VALUE and LAST_VALUE With Explicit Full Frame

```sql
-- Show each order alongside the smallest and largest order for that customer
SELECT order_id,
       customer_id,
       amount,
       FIRST_VALUE(amount) OVER (
           PARTITION BY customer_id
           ORDER BY amount ASC
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS customer_min_order,
       LAST_VALUE(amount) OVER (
           PARTITION BY customer_id
           ORDER BY amount ASC
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS customer_max_order
FROM   orders;
```

**Without the explicit frame**, `LAST_VALUE` with `ORDER BY` would use the default frame `UNBOUNDED PRECEDING AND CURRENT ROW` — making `LAST_VALUE` return the current row's own value (not the partition max). This is the classic `LAST_VALUE` trap.

---

### Example 6 — N PRECEDING: 7-Day Moving Sum Per Customer

```sql
-- Rolling 7-day order total per customer (RANGE with INTERVAL)
-- Supported in MySQL 8, PostgreSQL 11+
SELECT order_id,
       customer_id,
       order_date,
       amount,
       SUM(amount) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
           RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW
       ) AS rolling_7day_total
FROM   orders;
```

`RANGE BETWEEN INTERVAL 6 DAY PRECEDING` includes all rows within a 7-day lookback window per customer — not just the 7 physical rows before, but all rows whose date falls within 6 days before the current row's date.

---

## Default Frame Visual Summary

```
Window: OVER (ORDER BY order_date)         -- No explicit frame
Default frame: RANGE UNBOUNDED PRECEDING AND CURRENT ROW

  Partition rows (ordered by date):
  [Jan1] [Jan2] [Jan3] [Jan4] [Jan5]
              ↑ current row
  Frame:      [━━━━━━━━━━━━━━━━━━━━]
              All rows up to (and including same-date peers as) current row

Window: OVER (ORDER BY order_date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
  Frame (3-row symmetric window):
  [Jan1] [Jan2] [Jan3] [Jan4] [Jan5]
              ↑ current row
         [━━━━━━━━━━━━━━]
         prev  curr  next
```

---

## Interview Tips

1. **Know the default frame for `ORDER BY OVER`.** The single most common frame trap: `SUM(x) OVER (ORDER BY date)` is a running total, not a partition total, because the default frame is `RANGE UNBOUNDED PRECEDING AND CURRENT ROW`. State this clearly.

2. **ROWS vs RANGE only differs with ties.** On data with unique ORDER BY values, `ROWS` and `RANGE` produce identical results. They diverge only when duplicate sort key values exist. Have the side-by-side tied-date example ready.

3. **`LAST_VALUE` almost always needs an explicit frame.** This is the most common window function bug in production SQL. The fix: always add `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` for `FIRST_VALUE`/`LAST_VALUE`.

4. **Moving average = `ROWS BETWEEN N PRECEDING AND CURRENT ROW`.** Pattern: `AVG(col) OVER (ORDER BY date_col ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` = 3-period moving average. Adjust the number for different windows.

5. **`RANGE` with `INTERVAL` for true date-based windows.** When asked about "rolling 7-day sales," the correct approach is `RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW` — not `ROWS BETWEEN 6 PRECEDING`, because that counts physical rows regardless of date gaps.

---

## ❓ Practice Questions

1. Write a query to calculate a **3-order moving average** of `amount` for all orders, ordered by `order_date`. Use the `ROWS` frame mode. What changes if you use `RANGE` instead when multiple orders share the same date?

2. Using an explicit frame clause, show each employee's salary alongside:
   - The **cumulative salary** (running total) ordered by salary ascending within their department
   - The **total department salary** (full partition sum)
   
   Explain why you need different frames for each.

3. A developer wrote `LAST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY salary)` and complains it always returns the current row's salary, never the maximum. **Diagnose and fix** this query.

4. Write a query to calculate a **rolling 30-day total order amount per customer** using `RANGE BETWEEN INTERVAL 29 DAY PRECEDING AND CURRENT ROW`. Which rows in the output will have a smaller-than-expected window, and why?

5. Compare the output of these two queries on the `orders` table when two orders share the same `order_date`. Explain any differences:
   ```sql
   -- Query A
   SUM(amount) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
   
   -- Query B  
   SUM(amount) OVER (ORDER BY order_date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
   ```
