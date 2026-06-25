# SQL Execution Order — Why Your Query Runs the Way It Does

> **Interview Priority**: 🔴 Must Know

## What Is It?

SQL queries are **not executed in the order you write them**. The database engine processes clauses in a fixed logical order that is different from how they appear on screen. Understanding this order is the key to debugging query errors, knowing where to place conditions, and writing correct aggregations and window functions.

---

## The Logical Execution Order

```
Step 1:  FROM          → Load the source tables
Step 2:  JOIN          → Apply join conditions, combine tables
Step 3:  WHERE         → Filter individual rows (before grouping)
Step 4:  GROUP BY      → Collapse rows into groups
Step 5:  HAVING        → Filter groups (after aggregation)
Step 6:  SELECT        → Compute column expressions, assign aliases
Step 7:  DISTINCT      → Remove duplicate rows
Step 8:  ORDER BY      → Sort the result set
Step 9:  LIMIT/OFFSET  → Return only the specified rows
```

```sql
-- A query touching all clauses (read in SQL order, but executed in logical order above)
SELECT   d.dept_name,                        -- Step 6: computed last
         COUNT(e.emp_id)   AS headcount,
         AVG(e.salary)     AS avg_salary
FROM     employees e                         -- Step 1
JOIN     departments d                       -- Step 2
         ON e.dept_id = d.dept_id
WHERE    e.hire_date >= '2018-01-01'         -- Step 3: filter rows first
GROUP BY d.dept_id, d.dept_name              -- Step 4: group what remains
HAVING   COUNT(e.emp_id) > 1                 -- Step 5: filter groups
ORDER BY avg_salary DESC                     -- Step 8: sort final output
LIMIT    5;                                  -- Step 9: return top 5
```

---

## Syntax

```sql
SELECT   [DISTINCT] column_list
FROM     table_name
[JOIN    other_table ON condition]
[WHERE   row_filter_condition]
[GROUP BY grouping_columns]
[HAVING  group_filter_condition]
[ORDER BY sort_columns]
[LIMIT   n OFFSET m];
```

---

## Key Concepts

### Why Column Aliases in SELECT Can't Be Used in WHERE

`WHERE` runs at **Step 3**, but `SELECT` (where aliases are defined) runs at **Step 6**. The alias doesn't exist yet when WHERE is being processed.

```sql
-- ❌ WRONG: alias 'annual_salary' doesn't exist yet at WHERE step
SELECT salary * 12 AS annual_salary
FROM employees
WHERE annual_salary > 900000;
-- ERROR: Unknown column 'annual_salary' in 'where clause'

-- ✅ CORRECT: repeat the expression in WHERE
SELECT salary * 12 AS annual_salary
FROM employees
WHERE salary * 12 > 900000;

-- ✅ ALSO CORRECT: use a subquery or CTE
WITH computed AS (
    SELECT name, salary * 12 AS annual_salary
    FROM employees
)
SELECT name, annual_salary
FROM computed
WHERE annual_salary > 900000;
```

> **Exception**: MySQL and PostgreSQL allow using aliases in `ORDER BY` (Step 8) because ORDER BY runs after SELECT. But aliases still cannot be used in WHERE, HAVING, or GROUP BY in standard SQL.

---

### Why Aggregate Functions Can't Be in WHERE

`WHERE` filters individual rows at Step 3 — **before** `GROUP BY` (Step 4) and aggregation happen. Aggregate functions like `SUM()`, `COUNT()`, `AVG()` don't exist yet at the WHERE step.

```sql
-- ❌ WRONG: aggregate in WHERE
SELECT dept_id, COUNT(*) AS headcount
FROM employees
WHERE COUNT(*) > 2        -- ERROR: aggregates can't go in WHERE
GROUP BY dept_id;

-- ✅ CORRECT: use HAVING (runs after GROUP BY)
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 2;
```

```sql
-- ❌ WRONG: can't filter by average salary in WHERE
SELECT name, salary
FROM employees
WHERE salary > AVG(salary);   -- ERROR

-- ✅ CORRECT: use a subquery
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- ✅ ALSO CORRECT: use window function (computed after WHERE)
SELECT name, salary, dept_id,
       AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg
FROM employees;
-- Then wrap in CTE and filter on dept_avg
```

---

### Why Window Functions Execute After WHERE and GROUP BY

Window functions (like `ROW_NUMBER()`, `SUM() OVER`, `LAG()`) are computed at **Step 6** (SELECT), after WHERE and GROUP BY have already reduced the data. This means:

1. Window functions **see only the rows that survived WHERE**
2. Window functions **cannot be used in WHERE or HAVING directly**

```sql
-- ❌ WRONG: can't use window function in WHERE
SELECT name, salary,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
FROM employees
WHERE ROW_NUMBER() OVER (ORDER BY salary DESC) <= 3;  -- ERROR

-- ✅ CORRECT: wrap in a CTE or subquery
WITH ranked AS (
    SELECT name, salary,
           ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
    FROM employees
    WHERE dept_id = 10   -- WHERE filters happen before ROW_NUMBER is computed
)
SELECT name, salary, rn
FROM ranked
WHERE rn <= 3;
```

```sql
-- Window function sees only WHERE-filtered rows
WITH eng_ranked AS (
    SELECT name, salary,
           DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
    WHERE dept_id = 10   -- only Engineering employees
)
SELECT name, salary, rnk
FROM eng_ranked
WHERE rnk = 1;  -- top earner in Engineering
```

---

### DISTINCT Runs After SELECT but Before ORDER BY

`DISTINCT` removes duplicate rows from the SELECT output before sorting.

```sql
SELECT DISTINCT dept_id       -- Step 6: compute columns
FROM employees                -- Step 1
ORDER BY dept_id;             -- Step 8: sort distinct result
-- Returns: 10, 20, 30, 40 (each department once)
```

---

### LIMIT Runs Last — It Can't Be Used to Speed Up Earlier Steps

A common misconception: adding `LIMIT 10` does not help `WHERE` or `JOIN` run faster — the database still evaluates those steps first, then limits the final output.

```sql
-- The JOIN and WHERE still process all matching rows first
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 70000
LIMIT 5;
-- All matching rows are evaluated by WHERE/JOIN first; then top 5 are returned
```

---

## A Complete Worked Example

Let's trace the execution order of a real query step by step:

```sql
SELECT   d.dept_name,
         COUNT(e.emp_id)  AS headcount,
         MAX(e.salary)    AS top_salary
FROM     employees e
JOIN     departments d ON e.dept_id = d.dept_id
WHERE    e.hire_date >= '2019-01-01'
GROUP BY d.dept_id, d.dept_name
HAVING   COUNT(e.emp_id) >= 2
ORDER BY top_salary DESC
LIMIT    3;
```

**Step-by-step trace:**

| Step | Clause | What Happens |
|---|---|---|
| 1 | `FROM employees e` | Load all employee rows |
| 2 | `JOIN departments d ON ...` | Combine with matching department rows |
| 3 | `WHERE hire_date >= '2019-01-01'` | Remove employees hired before 2019 |
| 4 | `GROUP BY d.dept_id, d.dept_name` | Collapse remaining rows into dept groups |
| 5 | `HAVING COUNT(e.emp_id) >= 2` | Remove departments with fewer than 2 qualifying employees |
| 6 | `SELECT dept_name, COUNT(...), MAX(...)` | Compute the output columns; `headcount` alias defined |
| 7 | *(no DISTINCT)* | Skip |
| 8 | `ORDER BY top_salary DESC` | Sort by the alias (now valid since SELECT ran) |
| 9 | `LIMIT 3` | Return only the top 3 rows |

---

## Incorporated from rogue.md (Original Quick Notes)

The key points from the original notes:

```
SQL doesn't run top → bottom. It runs like this:
1. FROM
2. WHERE  ✅ (row filtering happens here)
3. GROUP BY
4. HAVING ✅ (group filtering happens here)
5. SELECT
6. ORDER BY
```

**WHERE cannot use aggregate functions:**
```sql
-- ❌ Wrong
SELECT department, COUNT(*)
FROM employees
WHERE COUNT(*) > 5   -- ERROR: aggregate not allowed here
GROUP BY department;

-- ✅ Correct
SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 5;
```

**Column alias:**
```sql
SELECT name AS student_name;
```
A label only — no storage change. Can be referenced in `ORDER BY` but NOT in `WHERE`, `HAVING`, or `GROUP BY` (in standard SQL).

**Creating a table from a query:**
```sql
CREATE TABLE new_table AS SELECT ...
```
This actually creates a **physical table** (not just a label). Different from a view.

---

## Interview Tips

1. **The most common question: "Why can't I use a SELECT alias in WHERE?"** — Answer confidently: SELECT runs at Step 6, WHERE runs at Step 3. The alias doesn't exist yet.

2. **"Why can't I use COUNT() in WHERE?"** — Aggregates require grouping (Step 4) which hasn't happened yet at WHERE (Step 3). Use HAVING instead.

3. **"Why does my window function error when I put it in WHERE?"** — Window functions are computed in the SELECT step (Step 6). To filter on them, wrap the query in a CTE or subquery.

4. **ORDER BY can use aliases** — Because ORDER BY runs after SELECT. This is often surprising to candidates and shows deep understanding when you explain why.

5. **Memorise the 9-step order** — Being able to recite `FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT` confidently signals strong fundamentals.

---

## ❓ Practice Questions

1. A classmate wrote this query and it fails. Explain **why** it fails and rewrite it correctly:
   ```sql
   SELECT dept_id, AVG(salary) AS avg_sal
   FROM employees
   WHERE avg_sal > 75000
   GROUP BY dept_id;
   ```

2. Write a query that finds departments where the **number of employees hired after 2020** is at least 2. Use the correct clause (WHERE vs HAVING) for each condition.

3. The following query should return the top 3 earners in Engineering. It errors. Fix it and explain the execution order issue:
   ```sql
   SELECT name, salary,
          ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
   FROM employees
   WHERE rn <= 3 AND dept_id = 10;
   ```

4. Write a query that shows each employee's name, salary, and **what percentage their salary is of their department's total salary**. Then filter to show only employees whose share exceeds 30%. Explain which steps process which part of your query.

5. Can you use a column alias (defined in SELECT) in GROUP BY? Test your understanding: write a query grouping by `YEAR(hire_date)` and give that expression an alias — then discuss whether the alias can be used in HAVING.
