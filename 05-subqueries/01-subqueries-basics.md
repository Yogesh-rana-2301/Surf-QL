# Subqueries — Queries Within Queries

> **Interview Priority**: 🔴 Must Know

## What Is It?

A **subquery** (also called an inner query or nested query) is a SQL query embedded inside another SQL query. The outer query uses the result of the inner query as a value, a set of values, or a derived table. Subqueries let you break complex problems into smaller, readable steps — and are one of the most tested topics in SQL interviews.

---

## Syntax

```sql
-- General structure
SELECT column_list
FROM   table_name
WHERE  column operator (
    SELECT column
    FROM   another_table
    WHERE  condition
);
```

The subquery always lives inside **parentheses** and can appear in the `SELECT`, `FROM`, `WHERE`, or `HAVING` clause.

---

## Key Concepts

### 1 · Types of Subqueries by Return Shape

| Type | Returns | Typical Operators |
|------|---------|-------------------|
| **Scalar subquery** | Exactly one row, one column (a single value) | `=`, `<`, `>`, `!=` |
| **Row subquery** | Exactly one row, multiple columns | `= (val1, val2)` — row constructor |
| **Table subquery** (inline view) | Multiple rows and columns | Used in `FROM` clause |
| **Column subquery** | Multiple rows, one column | `IN`, `ANY`, `ALL`, `EXISTS` |

### 2 · Subquery Execution Order

The **inner query runs first**; its result is handed to the outer query. This is true for *non-correlated* subqueries. (Correlated subqueries — see the next file — work differently.)

### 3 · Subqueries Are Read-Only Inside `WHERE`/`HAVING`

You cannot use `ORDER BY` inside a subquery unless you also use `TOP`/`LIMIT` (dialect-dependent). Results from the inner query are treated as a set.

### 4 · NULL Sensitivity

If a scalar subquery returns `NULL`, any arithmetic or comparison with it also yields `NULL`. If a column subquery used with `IN` returns a `NULL` among the values, rows **will not match** that `NULL` (because `x = NULL` is never `TRUE`). Keep this in mind when using `NOT IN`.

---

## Examples

### Example 1 — Scalar Subquery in `WHERE`: Employees Earning Above Company Average

```sql
-- Company-wide average salary
SELECT name, salary
FROM   employees
WHERE  salary > (
    SELECT AVG(salary)
    FROM   employees
);
```

The subquery `SELECT AVG(salary) FROM employees` returns a single number (e.g., 78 000). The outer query then filters every employee whose salary exceeds that figure.

**Expected output (approximate):**

| name | salary  |
|------|---------|
| Ravi | 91000.00|
| Aman | 85000.00|

---

### Example 2 — Scalar Subquery in `SELECT`: Show Each Employee's Salary vs Average

```sql
SELECT name,
       salary,
       (SELECT AVG(salary) FROM employees)          AS company_avg,
       salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM   employees;
```

> Every row "sees" the same scalar result from the subquery — no `GROUP BY` needed.

---

### Example 3 — Column Subquery with `IN`: Employees in Engineering or Finance

```sql
-- Get dept_ids first, then filter employees
SELECT name, dept_id
FROM   employees
WHERE  dept_id IN (
    SELECT dept_id
    FROM   departments
    WHERE  dept_name IN ('Engineering', 'Finance')
);
```

---

### Example 4 — Subquery in `FROM` (Inline View / Derived Table)

An inline view gives you a virtual table you can query like a real one. You **must** alias it.

```sql
-- Average salary per department, then find departments above company average
SELECT dept_summary.dept_id,
       dept_summary.avg_sal
FROM (
    SELECT dept_id,
           AVG(salary) AS avg_sal
    FROM   employees
    GROUP BY dept_id
) AS dept_summary
WHERE dept_summary.avg_sal > (
    SELECT AVG(salary) FROM employees
);
```

Here the inline view `dept_summary` pre-aggregates salary per department; the outer `WHERE` then filters using another scalar subquery for the overall average.

---

### Example 5 — Subquery in `HAVING`: Departments Whose Max Salary Exceeds a Threshold Set by Another Table

```sql
-- Departments where the top earner beats the overall company average
SELECT   d.dept_name,
         MAX(e.salary) AS top_salary
FROM     employees e
JOIN     departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING   MAX(e.salary) > (
    SELECT AVG(salary) FROM employees
);
```

`HAVING` filters groups — perfect for post-aggregation conditions that need a subquery scalar.

---

### Example 6 — Row Subquery: Find the Employee with the Same (dept_id, salary) as a Known Profile

```sql
-- Find any employee who shares both dept and salary with emp_id = 3
SELECT name
FROM   employees
WHERE  (dept_id, salary) = (
    SELECT dept_id, salary
    FROM   employees
    WHERE  emp_id = 3
);
```

Row subqueries compare multiple columns simultaneously using a row constructor `(col1, col2)`.

---

## Subquery vs JOIN — When to Use Which

| Scenario | Prefer | Why |
|----------|--------|-----|
| Filtering using a value from another table | Subquery or JOIN | Both work; JOIN gives full row access |
| Need columns from the subquery's table | JOIN | Subqueries in `WHERE` can't expose other columns |
| Aggregate as a filter (`> AVG(...)`) | Scalar subquery | Simple and expressive |
| Complex derived sets, reused logic | CTE (see module 06) | More readable than nested subqueries |
| Large datasets, performance-critical | JOIN | Joins are usually optimised better by the engine |
| Check existence only | EXISTS subquery | Stops at first match; often faster than `IN` |

```sql
-- Same result — salary above average — written as a JOIN
SELECT e.name, e.salary
FROM   employees e
JOIN (
    SELECT AVG(salary) AS avg_sal FROM employees
) avg_table ON e.salary > avg_table.avg_sal;
```

---

## Interview Tips

1. **Know the four placement positions.** Interviewers ask: *"Where can a subquery appear?"* — Answer: `SELECT`, `FROM`, `WHERE`, `HAVING` (and also `JOIN ON` in some dialects).

2. **Scalar subquery contract.** If a scalar subquery accidentally returns more than one row, the query errors at runtime. Mention this when asked about common bugs.

3. **Inline view must be aliased.** `FROM (SELECT ...) AS alias` — forgetting `AS alias` is a syntax error. Simple but often missed.

4. **Subquery vs JOIN trade-off.** The canonical interview question. Key points: JOINs expose more columns; subqueries are more self-contained; for existence checks, `EXISTS` is preferred; for complex reuse, use CTEs.

5. **`NOT IN` + NULL trap.** If the subquery for `NOT IN` returns even one `NULL`, the entire result set is empty — because `x NOT IN (1, 2, NULL)` is never `TRUE`. Prefer `NOT EXISTS` to avoid this.

---

## ❓ Practice Questions

1. Write a query to find all employees whose salary is **above the average salary of the HR department** (dept_id = 20). Use a scalar subquery.

2. Using a subquery in the `FROM` clause, calculate the **total orders per customer**, then display only customers whose total exceeds **5 000**.

3. Find the **names and salaries** of employees who work in the same department as `'Ravi'`. Use a subquery — do not hard-code the dept_id.

4. Write a query using a subquery in `HAVING` to list **product categories** where the **maximum product price** exceeds the **average price across all products**.

5. Rewrite the following using a `JOIN` instead of a subquery, and explain what changes:
   ```sql
   SELECT name FROM employees
   WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'New York');
   ```
