# Common Table Expressions (CTEs) — Named, Reusable Query Blocks

> **Interview Priority**: 🔴 Must Know

## What Is It?

A **Common Table Expression (CTE)** is a named temporary result set defined at the top of a query using the `WITH` keyword. It lives only for the duration of that single SQL statement and can be referenced like a table anywhere within the main query. CTEs make complex queries readable by letting you name intermediate steps — think of them as "giving a subquery a variable name."

---

## Syntax

```sql
-- Single CTE
WITH cte_name AS (
    SELECT ...
    FROM   ...
    WHERE  ...
)
SELECT *
FROM   cte_name
WHERE  ...;

-- Multiple CTEs (comma-separated)
WITH
cte_one AS (
    SELECT ...
),
cte_two AS (
    SELECT ...
    FROM   cte_one   -- later CTEs can reference earlier ones
)
SELECT *
FROM   cte_two;
```

> **Rules:**
> - `WITH` goes **before** the main `SELECT`/`INSERT`/`UPDATE`/`DELETE`.
> - Each CTE is separated by a **comma** — no comma after the last one.
> - CTEs are **not** stored in the database; they exist only for the duration of the statement.

---

## Key Concepts

### 1 · CTE vs Subquery — Head-to-Head

| Feature | CTE | Subquery |
|---------|-----|----------|
| **Named / reusable** | ✅ Can be referenced multiple times | ❌ Must be duplicated each time |
| **Readability** | ✅ Top-down logic flow | ❌ Nested inside-out |
| **Recursion** | ✅ Supported via `WITH RECURSIVE` | ❌ Not possible |
| **Debugging** | ✅ Easy to isolate and test each CTE | ❌ Hard to debug nested subqueries |
| **DML support** | ✅ Can be used with INSERT/UPDATE/DELETE | ✅ Also possible, but less clean |
| **Performance** | ⚠️ Optimizer-dependent (see note below) | ⚠️ Same |
| **Scope** | Single statement only | Single clause only |

### 2 · CTEs Are Not Always Faster

A persistent myth: *"CTEs cache results so they're faster."*  
**Reality depends on the database engine:**

- **PostgreSQL (pre-v12):** CTEs were treated as *optimization fences* — the engine materialised CTE results and couldn't push predicates through them. This could make CTEs **slower** than equivalent subqueries.
- **PostgreSQL v12+:** The planner can inline CTEs when safe (controlled by `MATERIALIZED` / `NOT MATERIALIZED` hints).
- **MySQL / SQL Server / Oracle:** Generally inline CTEs into the main query plan (similar to subqueries).

**Takeaway:** Write CTEs for clarity; always `EXPLAIN` before assuming performance.

### 3 · A CTE Can Be Referenced Multiple Times

Unlike a subquery that must be copy-pasted, a CTE defined once can appear in multiple `JOIN`s or `WHERE` clauses within the same statement — this is one of their biggest practical advantages.

### 4 · CTEs with DML

CTEs are valid before `INSERT`, `UPDATE`, and `DELETE` — not just `SELECT`. This enables clean, readable data modifications.

---

## Examples

### Example 1 — Basic CTE: Departments With Above-Average Salary

```sql
WITH dept_avg AS (
    SELECT dept_id,
           AVG(salary) AS avg_sal
    FROM   employees
    GROUP BY dept_id
),
company_avg AS (
    SELECT AVG(salary) AS overall_avg
    FROM   employees
)
SELECT d.dept_name,
       da.avg_sal,
       ca.overall_avg
FROM   dept_avg da
JOIN   departments d   ON da.dept_id = d.dept_id
CROSS JOIN company_avg ca
WHERE  da.avg_sal > ca.overall_avg
ORDER BY da.avg_sal DESC;
```

**Step-by-step reading:**
1. `dept_avg` — compute average salary per department.
2. `company_avg` — compute the single company-wide average.
3. Main query — join them, filter departments where their average beats the company average.

This would be a deeply nested mess as inline subqueries.

---

### Example 2 — CTE Reused Twice: Rank Employees, Then Filter Top and Bottom

```sql
WITH ranked_employees AS (
    SELECT emp_id,
           name,
           salary,
           dept_id,
           RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk_high,
           RANK() OVER (PARTITION BY dept_id ORDER BY salary ASC)  AS rnk_low
    FROM   employees
)
-- Top earner per department
SELECT 'Top Earner' AS label, name, salary, dept_id
FROM   ranked_employees
WHERE  rnk_high = 1

UNION ALL

-- Bottom earner per department
SELECT 'Bottom Earner', name, salary, dept_id
FROM   ranked_employees        -- ← same CTE, referenced again
WHERE  rnk_low = 1;
```

The CTE `ranked_employees` is referenced **twice** in the same query — impossible with a regular subquery without copy-pasting.

---

### Example 3 — CTE with UPDATE (DML)

```sql
-- Give a 10% bonus raise to employees rated 'A' in 2023
WITH top_performers AS (
    SELECT emp_id
    FROM   performance
    WHERE  year   = 2023
      AND  rating = 'A'
)
UPDATE employees
SET    salary = salary * 1.10
WHERE  emp_id IN (SELECT emp_id FROM top_performers);
```

> Note: Some databases (PostgreSQL) allow `UPDATE ... FROM cte_name` directly; MySQL requires the `IN (SELECT ...)` pattern shown above.

---

### Example 4 — CTE with DELETE: Remove Customers With No Orders

```sql
WITH inactive_customers AS (
    SELECT c.customer_id
    FROM   customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE  o.order_id IS NULL
)
DELETE FROM customers
WHERE  customer_id IN (SELECT customer_id FROM inactive_customers);
```

---

### Example 5 — Chained CTEs: Find Top-Spending Customer Per City

```sql
WITH customer_totals AS (
    -- Step 1: Total spend per customer
    SELECT customer_id,
           SUM(amount) AS total_spent
    FROM   orders
    GROUP BY customer_id
),
customer_ranked AS (
    -- Step 2: Rank customers within each city by spend
    SELECT c.customer_id,
           c.name,
           c.city,
           ct.total_spent,
           RANK() OVER (PARTITION BY c.city ORDER BY ct.total_spent DESC) AS city_rank
    FROM   customers c
    JOIN   customer_totals ct ON c.customer_id = ct.customer_id
)
-- Step 3: Pick the top spender from each city
SELECT name, city, total_spent
FROM   customer_ranked
WHERE  city_rank = 1;
```

Each CTE builds on the previous — the query reads like a story from top to bottom.

---

## CTE vs Subquery — When to Use Each

```
Use a CTE when:
  ✅ You need to reference the same derived result more than once
  ✅ The query has multiple logical steps that should read sequentially
  ✅ You need recursion (employee hierarchy, category trees)
  ✅ You are writing a DML statement that needs a named pre-filter

Use a subquery when:
  ✅ The derivation is used exactly once and is short
  ✅ You want to keep the query self-contained in a single expression
  ✅ You are in an environment where CTEs have known optimization fences
```

---

## Interview Tips

1. **CTE = named subquery, scoped to one statement.** When asked "what is a CTE?", lead with this definition and immediately contrast with subqueries on readability and recursion.

2. **CTEs are not always faster — mention the optimizer.** Interviewers respect candidates who acknowledge that CTEs can act as optimization fences in some databases (PostgreSQL pre-v12 especially). Showing this nuance separates good from great.

3. **CTE reusability is the killer feature.** The most compelling reason to use a CTE over a subquery is the ability to reference it multiple times without duplication. Have an example ready.

4. **You can nest CTEs (chain them).** Later CTEs can reference earlier ones. The order of definition matters — you cannot forward-reference a CTE.

5. **`WITH RECURSIVE` is the gateway to hierarchical queries.** If asked about CTEs, mention recursive CTEs as an extension — it shows you know the full capability. (Details in the next file.)

---

## ❓ Practice Questions

1. Write a **CTE** called `high_value_orders` that selects all orders with `amount > 1000`, then use it to find the **names of customers** who placed at least one such order.

2. Using **two CTEs**, find the department with the **highest average salary** and display the names of all employees in that department.

3. Write a CTE-based query to find all **employees who earned a bonus in the `performance` table that is above the average bonus for their rating category** (e.g., above average for all 'A' performers).

4. Use a CTE with an `UPDATE` statement to **increase prices by 15%** for all products in the `'Electronics'` category that have a price below 500.

5. Explain in words (or rewrite) how the following subquery-based query could be improved using CTEs for readability:
   ```sql
   SELECT name FROM customers
   WHERE customer_id IN (
       SELECT customer_id FROM orders
       WHERE amount > (SELECT AVG(amount) FROM orders)
       AND status = 'Delivered'
   );
   ```
