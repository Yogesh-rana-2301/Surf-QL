# Correlated Subqueries — The Row-by-Row Inner Query

> **Interview Priority**: 🔴 Must Know

## What Is It?

A **correlated subquery** is a subquery that **references a column from the outer query**. Unlike a regular (non-correlated) subquery which runs once and hands its result to the outer query, a correlated subquery **re-executes for every row** the outer query processes. This makes it powerful but potentially slow — and understanding that trade-off is exactly what interviewers test.

---

## Syntax

```sql
SELECT outer_col1, outer_col2
FROM   outer_table  alias_outer
WHERE  outer_col  operator (
    SELECT aggregate_or_value
    FROM   inner_table  alias_inner
    WHERE  alias_inner.some_col = alias_outer.linking_col   -- ← the correlation
);
```

The key line is the `WHERE` clause inside the subquery that **references `alias_outer`** — a column from the enclosing query. That reference is what makes the subquery "correlated."

---

## Key Concepts

### 1 · Execution Model (Why It's Slow)

```
For each row in outer_table:
    Run the subquery with that row's values substituted
    Compare the result against the outer WHERE condition
    Include or exclude the row
```

If `employees` has 10 000 rows, the subquery runs **10 000 times**. For large tables this causes serious performance problems — an O(N²) scan pattern in the worst case.

### 2 · Correlation vs Non-Correlation — Side-by-Side

```sql
-- NON-CORRELATED: runs once, result is a constant
SELECT name, salary
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees);
--                ^^^^ no outer reference — fixed result

-- CORRELATED: runs once per employee row
SELECT name, salary
FROM   employees e_outer
WHERE  salary > (
    SELECT AVG(salary)
    FROM   employees e_inner
    WHERE  e_inner.dept_id = e_outer.dept_id  -- ← outer reference
);
```

### 3 · Aliases Are Mandatory

Because the inner query must distinguish its own copy of the table from the outer copy, **table aliases are not optional** in correlated subqueries — they are required for correctness.

### 4 · Common Use Cases

- Per-group comparison (salary vs department average)
- Latest record per entity (most recent order per customer)
- Existence checks per row (`EXISTS` — covered in the next file)
- Finding duplicates or anomalies within a partition

---

## Examples

### Example 1 — Employees Earning More Than Their Department's Average

```sql
-- Correlated version
SELECT e.name,
       e.salary,
       e.dept_id
FROM   employees e
WHERE  e.salary > (
    SELECT AVG(i.salary)
    FROM   employees i
    WHERE  i.dept_id = e.dept_id   -- correlated: uses e.dept_id from outer row
);
```

**How it runs:**
- Row 1: Aman, dept_id=10 → subquery computes `AVG(salary) WHERE dept_id=10` → compare → include/exclude
- Row 2: Dev, dept_id=10 → subquery runs **again** for dept_id=10 → compare → …
- Row 3: Priya, dept_id=20 → subquery computes `AVG(salary) WHERE dept_id=20` → …
- …and so on for every single employee.

---

### Example 2 — Each Customer's Most Recent Order Date

```sql
-- Find customers along with the date of their latest order
SELECT c.name,
       c.city,
       (
           SELECT MAX(o.order_date)
           FROM   orders o
           WHERE  o.customer_id = c.customer_id   -- correlated
       ) AS latest_order_date
FROM   customers c;
```

Here the correlated subquery sits in the `SELECT` list rather than `WHERE` — it computes a per-customer scalar value for every output row.

---

### Example 3 — Products Ordered at Least Once (using EXISTS, correlated)

```sql
SELECT p.product_name, p.category
FROM   products p
WHERE  EXISTS (
    SELECT 1
    FROM   orders o
    WHERE  o.product_id = p.product_id   -- correlated
);
```

`EXISTS` is effectively a correlated subquery that stops at the first matching row — making it efficient even on large datasets (covered thoroughly in file 03).

---

## Rewriting as JOIN + GROUP BY for Performance

The canonical interview follow-up: *"How would you optimise that correlated subquery?"*

```sql
-- CORRELATED version (runs N subqueries)
SELECT e.name, e.salary, e.dept_id
FROM   employees e
WHERE  e.salary > (
    SELECT AVG(i.salary)
    FROM   employees i
    WHERE  i.dept_id = e.dept_id
);

-- OPTIMISED: JOIN + GROUP BY (subquery runs once per department)
SELECT e.name, e.salary, e.dept_id
FROM   employees e
JOIN (
    SELECT dept_id,
           AVG(salary) AS dept_avg
    FROM   employees
    GROUP BY dept_id
) dept_avgs ON e.dept_id = dept_avgs.dept_id
WHERE  e.salary > dept_avgs.dept_avg;
```

**Why this is faster:**
- The inner `GROUP BY` query runs **once** and produces one row per department.
- The `JOIN` then matches each employee to their department's pre-computed average in a single pass.
- No repeated subquery execution per outer row.

```sql
-- WINDOW FUNCTION alternative (often fastest — single table scan)
SELECT name, salary, dept_id
FROM (
    SELECT name,
           salary,
           dept_id,
           AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg
    FROM   employees
) ranked
WHERE salary > dept_avg;
```

---

### Full Comparison Table

| Approach | Subquery Executions | Best When |
|----------|--------------------|-----------| 
| Correlated subquery | Once per outer row (N times) | Small tables, complex per-row logic hard to express as join |
| JOIN + GROUP BY derived table | Once total | Most production use cases; large tables |
| Window function | Single table scan | Per-partition aggregates; cleanest code |

---

## Interview Tips

1. **Lead with the execution model.** When asked about correlated subqueries, immediately say: *"It re-executes for every row of the outer query, which makes it O(N) subquery calls."* This signals strong understanding.

2. **Know the rewrite.** Interviewers almost always follow up with: *"How would you rewrite this for better performance?"* Have the `JOIN + GROUP BY` pattern ready, and mention window functions as the cleanest alternative.

3. **Aliases are not optional.** If you write a correlated subquery without aliases, the engine can't distinguish the inner table scan from the outer one. Always alias both copies.

4. **Correlated in SELECT vs WHERE.** Correlated subqueries in the `SELECT` list compute a scalar per row (useful for "show each row's group aggregate"). Those in `WHERE` filter rows. Both re-execute per row — same performance concern.

5. **EXISTS is a correlated subquery.** Many candidates treat `EXISTS` as separate from "correlated subqueries" — they're the same mechanism. `EXISTS` just discards the actual values and returns a boolean, stopping at the first match.

---

## ❓ Practice Questions

1. Write a **correlated subquery** to find all employees whose salary is **higher than the average salary of their own department**. Display their name, department, and salary.

2. Using a **correlated subquery in the SELECT clause**, display each customer's name alongside the **count of orders** they have placed.

3. Find all **products** that have **never been ordered** — use a correlated subquery with `NOT EXISTS`.

4. Rewrite the following correlated subquery as a **JOIN + GROUP BY** and explain the performance difference:
   ```sql
   SELECT name, salary
   FROM   employees e
   WHERE  salary = (
       SELECT MAX(salary)
       FROM   employees i
       WHERE  i.dept_id = e.dept_id
   );
   ```

5. For each employee in the `performance` table, find those whose **bonus is above the average bonus for their rating grade** (e.g., all 'A' performers whose bonus exceeds the average 'A' bonus). Use a correlated subquery.
