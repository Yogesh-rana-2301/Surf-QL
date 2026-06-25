# SQL CTE Guide (How To Use + Interview Focus)

This file explains how to use CTEs clearly, with examples and interview-level comparisons against subqueries.

## 1) What Is a CTE?

CTE means Common Table Expression.
It is a temporary named result set that exists only for one SQL statement.

General syntax:

```sql
WITH cte_name AS (
  SELECT ...
)
SELECT ...
FROM cte_name;
```

Think of it as writing a readable, reusable mini-query before the main query.

## 2) Why Use CTE?

- Improves readability for complex queries.
- Breaks one big query into smaller logical steps.
- Allows multiple references to the same intermediate result.
- Supports recursion (for trees/hierarchies).

## 3) Basic CTE Example

Goal: Get employees earning above company average.

```sql
WITH avg_salary_cte AS (
  SELECT AVG(salary) AS avg_salary
  FROM employees
)
SELECT e.emp_id, e.name, e.salary
FROM employees e
JOIN avg_salary_cte a ON 1 = 1
WHERE e.salary > a.avg_salary;
```

Equivalent approach without CTE usually uses nested subquery.

## 4) CTE with Aggregation and Filtering

Goal: Find departments where average salary is above 70000.

```sql
WITH dept_salary AS (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
)
SELECT dept_id, avg_salary
FROM dept_salary
WHERE avg_salary > 70000;
```

This is often cleaner than repeating the same aggregation logic in nested queries.

## 5) Multiple CTEs in One Query

You can chain multiple CTEs.

```sql
WITH dept_salary AS (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
),
ranked_depts AS (
  SELECT
    dept_id,
    avg_salary,
    DENSE_RANK() OVER (ORDER BY avg_salary DESC) AS rnk
  FROM dept_salary
)
SELECT *
FROM ranked_depts
WHERE rnk <= 3;
```

Use this style for interview queries where logic has multiple stages.

## 6) Recursive CTE (Very Important for Trees/Hierarchies)

Use recursive CTE when rows reference rows in the same table.
Example: Employee-manager hierarchy.

```sql
WITH RECURSIVE org_tree AS (
  -- Anchor row(s): top-level managers
  SELECT emp_id, name, manager_id, 1 AS level
  FROM employees
  WHERE manager_id IS NULL

  UNION ALL

  -- Recursive part: pick employees under previous level
  SELECT e.emp_id, e.name, e.manager_id, o.level + 1
  FROM employees e
  JOIN org_tree o ON e.manager_id = o.emp_id
)
SELECT *
FROM org_tree
ORDER BY level, emp_id;
```

Interview point:

- Anchor query gives starting nodes.
- Recursive query keeps expanding until no more rows are found.

## 7) CTE with DML (UPDATE/DELETE/INSERT)

Many DBs allow CTE before DML.

### UPDATE using CTE

```sql
WITH high_performers AS (
  SELECT emp_id
  FROM performance
  WHERE rating = 'A'
)
UPDATE employees
SET salary = salary * 1.10
WHERE emp_id IN (SELECT emp_id FROM high_performers);
```

### DELETE using CTE

```sql
WITH inactive_customers AS (
  SELECT customer_id
  FROM customers
  WHERE last_login < DATE '2022-01-01'
)
DELETE FROM orders
WHERE customer_id IN (SELECT customer_id FROM inactive_customers);
```

## 8) CTE vs Subquery: When to Use What?

### Use CTE when:

- Query is complex and you want clean, step-wise logic.
- Same intermediate result is used more than once.
- You need recursion.
- You want interview-friendly readability.

### Use Subquery when:

- Query is short and used only once.
- Inline expression is simple and obvious.
- You want compact SQL for straightforward conditions.

## 9) Practical Comparison

### Subquery version (compact)

```sql
SELECT name, salary
FROM employees
WHERE salary > (
  SELECT AVG(salary)
  FROM employees
);
```

### CTE version (more readable in bigger workflows)

```sql
WITH avg_salary_cte AS (
  SELECT AVG(salary) AS avg_salary
  FROM employees
)
SELECT name, salary
FROM employees
WHERE salary > (SELECT avg_salary FROM avg_salary_cte);
```

For this tiny case, both are fine.
For larger multi-step logic, CTE is usually easier to maintain and explain.

## 10) Performance Notes (Important in Interviews)

- CTE is mainly a readability tool; performance depends on database optimizer.
- Some engines may materialize CTEs; others inline/optimize them.
- Do not assume CTE is always faster than subquery.
- Always verify with EXPLAIN/EXPLAIN ANALYZE on your DB.

## 11) Common Mistakes

- Forgetting that CTE scope is only one statement.
- Missing column aliases in recursive CTE outputs.
- Using recursion without termination condition awareness.
- Assuming behavior is identical across all databases.

## 12) Interview-Ready Summary

- CTE = named temporary result set for one query.
- Best for readability, multi-step logic, and recursion.
- Subquery = concise for small one-time logic.
- For performance claims, say: check query plan on actual DB.
