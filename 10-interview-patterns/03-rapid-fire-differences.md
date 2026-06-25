# Rapid-Fire SQL Differences — Interview Cheatsheet

> **Interview Priority**: 🔴 Must Know

## What Is It?

This is your 10-minute pre-interview review card. Every section covers a classic "What's the difference between X and Y?" question. Answers are kept crisp — 2–4 lines each. Memorise these cold.

---

## 1. DELETE vs TRUNCATE vs DROP

| | DELETE | TRUNCATE | DROP |
|---|---|---|---|
| **What it does** | Removes specific rows (or all rows if no WHERE) | Removes all rows from a table | Removes the entire table (structure + data) |
| **WHERE clause** | ✅ Supported | ❌ Not supported | ❌ Not applicable |
| **Transaction** | DML — can be rolled back | DDL — auto-committed (cannot rollback in most DBs) | DDL — auto-committed |
| **Speed** | Slower (row-by-row, logs each delete) | Faster (deallocates data pages) | Fastest |
| **Triggers** | Fires DELETE triggers | Does NOT fire triggers | Does NOT fire triggers |
| **Auto-increment** | Counter NOT reset | Counter reset to 1 | Table is gone |
| **Identity preserved** | ✅ Table stays | ✅ Table stays (structure) | ❌ Table gone |

```sql
DELETE FROM employees WHERE dept_id = 40;  -- removes Marketing employees
TRUNCATE TABLE employees;                  -- removes ALL rows, table stays
DROP TABLE employees;                      -- table no longer exists
```

> **Key interview line**: "TRUNCATE is faster than DELETE because it deallocates data pages rather than logging individual row deletions. But it cannot be rolled back and doesn't fire triggers."

---

## 2. WHERE vs HAVING

| | WHERE | HAVING |
|---|---|---|
| **When it runs** | Before GROUP BY (filters rows) | After GROUP BY (filters groups) |
| **Used with** | Any column or expression | Aggregate functions or grouped columns |
| **Aggregate functions** | ❌ Cannot use (not yet computed) | ✅ Yes — this is its purpose |

```sql
-- WHERE filters individual rows before grouping
SELECT dept_id, AVG(salary)
FROM employees
WHERE salary > 50000          -- filter rows first
GROUP BY dept_id
HAVING AVG(salary) > 75000;  -- then filter groups
```

> **Key rule**: If you need to filter on the *result of an aggregate*, use HAVING. You cannot write `WHERE AVG(salary) > 75000`.

---

## 3. INNER JOIN vs LEFT JOIN

| | INNER JOIN | LEFT JOIN |
|---|---|---|
| **Returns** | Only rows with matches in BOTH tables | All rows from left table; NULLs for unmatched right table |
| **Unmatched rows** | Dropped | Kept (with NULLs in right columns) |
| **Use case** | When you only want records with related data | When you want all records from the primary table |

```sql
-- INNER JOIN: only employees who have a department
SELECT e.name, d.dept_name
FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id;

-- LEFT JOIN: all employees, even those with no matching department
SELECT e.name, d.dept_name   -- NULL if no dept
FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id;
```

> **RIGHT JOIN** is LEFT JOIN with tables swapped. Prefer LEFT JOIN for clarity. **FULL OUTER JOIN** returns all rows from both sides.

---

## 4. UNION vs UNION ALL

| | UNION | UNION ALL |
|---|---|---|
| **Duplicate rows** | Removed (implicit DISTINCT) | Kept — all rows returned |
| **Performance** | Slower (requires deduplication sort) | Faster |
| **Use case** | When duplicates are logically wrong | When duplicates are valid or you know there are none |

```sql
-- UNION: distinct city names from employees and customers
SELECT city FROM departments
UNION
SELECT city FROM customers;   -- duplicates removed

-- UNION ALL: all city names including duplicates
SELECT city FROM departments
UNION ALL
SELECT city FROM customers;   -- faster, may have duplicate city names
```

> Both require the **same number of columns** with **compatible data types**. Column names come from the first SELECT.

---

## 5. RANK vs DENSE_RANK vs ROW_NUMBER

| | ROW_NUMBER | RANK | DENSE_RANK |
|---|---|---|---|
| **Ties** | No ties — unique sequential numbers | Ties share rank; gaps after ties | Ties share rank; NO gaps |
| **Output for (100, 90, 90, 80)** | 1, 2, 3, 4 | 1, 2, 2, 4 | 1, 2, 2, 3 |
| **Use case** | Deduplication, exact pagination | Official rankings (e.g., sports leaderboards) | Salary ranking, Nth highest |

```sql
SELECT name, salary,
       ROW_NUMBER()  OVER (ORDER BY salary DESC) AS row_num,
       RANK()        OVER (ORDER BY salary DESC) AS rnk,
       DENSE_RANK()  OVER (ORDER BY salary DESC) AS dense_rnk
FROM employees;
```

> **For "Nth highest salary" questions, always use DENSE_RANK.** `RANK` skips numbers after ties; `ROW_NUMBER` arbitrarily breaks ties.

---

## 6. PRIMARY KEY vs UNIQUE KEY

| | PRIMARY KEY | UNIQUE KEY |
|---|---|---|
| **NULLs allowed** | ❌ No (implicitly NOT NULL) | ✅ One NULL per column (in most DBs) |
| **Count per table** | Only ONE per table | Multiple allowed |
| **Clustered index** | Usually creates clustered index | Creates non-clustered index |
| **Purpose** | Uniquely identifies every row | Ensures a column has no duplicate values |

```sql
CREATE TABLE employees (
    emp_id  INT PRIMARY KEY,           -- one PK, no NULLs
    email   VARCHAR(120) UNIQUE,       -- can have multiple UNIQUE columns
    name    VARCHAR(100) NOT NULL
);
```

> A PRIMARY KEY is essentially `UNIQUE + NOT NULL`, but only one is allowed per table.

---

## 7. EXISTS vs IN (including the NULL Trap)

| | IN | EXISTS |
|---|---|---|
| **Evaluates** | All values in the subquery result set | Stops at first match (short-circuit) |
| **NULL behavior** | ⚠️ `NOT IN` with a NULL in subquery → empty result | ✅ Safe — checks existence, not value equality |
| **Performance** | Better for small, indexed subqueries | Better for large subqueries or correlated checks |

```sql
-- IN: find customers who have placed orders
SELECT name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- EXISTS: same result, but stops at first match per customer
SELECT name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);
```

**The NULL Trap with NOT IN:**
```sql
-- If orders has even ONE row with customer_id = NULL:
SELECT name FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders);
-- Returns EMPTY — because NULL = NULL is UNKNOWN, not TRUE

-- Safe alternative: use NOT EXISTS
SELECT name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);
```

> **Rule of thumb**: Always prefer `NOT EXISTS` over `NOT IN` when the subquery could contain NULLs.

---

## 8. CTE vs Subquery

| | CTE | Subquery |
|---|---|---|
| **Readability** | ✅ Named, readable, reusable within the same query | 🟡 Can get deeply nested and hard to read |
| **Reusability** | ✅ Can be referenced multiple times in the same query | ❌ Must repeat if used more than once |
| **Recursion** | ✅ Supports recursive CTEs | ❌ Not supported |
| **Performance** | Usually similar; some DBs materialize CTEs | May be optimized inline by the query planner |
| **Scope** | Only within the query it's defined in | Local to its position in the outer query |

```sql
-- Subquery (nested, harder to read)
SELECT name FROM employees
WHERE dept_id IN (
    SELECT dept_id FROM departments WHERE location = 'Bangalore'
);

-- CTE (clean, named)
WITH bangalore_depts AS (
    SELECT dept_id FROM departments WHERE location = 'Bangalore'
)
SELECT name FROM employees
WHERE dept_id IN (SELECT dept_id FROM bangalore_depts);
```

> For anything with more than one step, prefer CTEs. They're easier to debug and impress interviewers.

---

## 9. COMMIT vs ROLLBACK

| | COMMIT | ROLLBACK |
|---|---|---|
| **Action** | Permanently saves all changes since the last commit | Undoes all changes since the last commit (or to a SAVEPOINT) |
| **After this** | Data is durable — other sessions can see it | Data reverts to the pre-transaction state |
| **Use case** | Finalizing a successful transaction | Handling an error — "undo everything" |

```sql
BEGIN;
  UPDATE employees SET salary = salary * 1.10 WHERE dept_id = 10;
  UPDATE performance SET bonus = 5000 WHERE year = 2024;
COMMIT;    -- both updates saved permanently

-- OR if something went wrong:
ROLLBACK;  -- both updates undone
```

> `SAVEPOINT name` creates a checkpoint within a transaction. `ROLLBACK TO SAVEPOINT name` reverts only to that point, not the entire transaction.

---

## 10. DDL vs DML vs DCL vs TCL

| Category | Full Name | Commands | Effect |
|---|---|---|---|
| **DDL** | Data Definition Language | `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `RENAME` | Defines/changes database structure |
| **DML** | Data Manipulation Language | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | Manipulates data within tables |
| **DCL** | Data Control Language | `GRANT`, `REVOKE` | Controls access/permissions |
| **TCL** | Transaction Control Language | `COMMIT`, `ROLLBACK`, `SAVEPOINT`, `BEGIN` | Manages transactions |

> Note: Some classify `SELECT` separately as **DQL** (Data Query Language). DDL statements are auto-committed in most databases.

---

## 11. Clustered vs Non-Clustered Index

| | Clustered Index | Non-Clustered Index |
|---|---|---|
| **Data order** | Physically sorts and stores table data in key order | Separate structure; stores pointers to actual rows |
| **Count per table** | Only ONE (table can only be physically sorted one way) | Many (SQL Server: up to 999) |
| **Lookup speed** | Fastest for range queries on the indexed key | Requires a lookup to get the actual row (two steps) |
| **Primary Key** | Usually the clustered index by default | Any other indexed column |

```sql
-- Clustered: employees sorted physically by emp_id
CREATE TABLE employees (emp_id INT PRIMARY KEY CLUSTERED, ...);

-- Non-clustered: separate index on email for fast lookups
CREATE INDEX idx_employee_email ON employees(email);
```

> **Analogy**: Clustered index = dictionary (words sorted alphabetically — data IS the index). Non-clustered = book index (separate pages pointing to where to find the content).

---

## 12. View vs Materialized View

| | View | Materialized View |
|---|---|---|
| **Data stored** | ❌ No — query is re-executed on each access | ✅ Yes — results are physically stored |
| **Freshness** | Always current (re-runs underlying query) | Can be stale — must be refreshed manually or on schedule |
| **Performance** | Slower for complex queries (recomputed each time) | Much faster for reads (precomputed) |
| **Storage** | None | Requires additional disk space |
| **Use case** | Security, simplification, always-fresh data | Reporting, dashboards, expensive aggregations |

```sql
-- Regular view: always runs the underlying query
CREATE VIEW dept_salary_summary AS
SELECT dept_id, AVG(salary) AS avg_salary FROM employees GROUP BY dept_id;

-- Materialized view (PostgreSQL):
CREATE MATERIALIZED VIEW dept_salary_mv AS
SELECT dept_id, AVG(salary) AS avg_salary FROM employees GROUP BY dept_id;

REFRESH MATERIALIZED VIEW dept_salary_mv;  -- manually update stored data
```

> MySQL does not support native materialized views. PostgreSQL and Oracle do. SQL Server uses "indexed views" for a similar effect.

---

## 13. CHAR vs VARCHAR

| | CHAR(n) | VARCHAR(n) |
|---|---|---|
| **Storage** | Fixed length — always uses n bytes | Variable length — uses only what's needed + 1-2 bytes overhead |
| **Padding** | Right-pads with spaces to reach n | No padding |
| **Speed** | Slightly faster (fixed-width rows easier to navigate) | Slightly slower due to variable size |
| **Best for** | Fixed-length data: country codes, status flags, phone formats | Variable-length data: names, emails, descriptions |

```sql
CREATE TABLE example (
    status     CHAR(1),         -- 'A', 'B', 'C' — always 1 char
    country    CHAR(2),         -- 'IN', 'US' — always 2 chars
    name       VARCHAR(100),    -- up to 100 chars, uses only what's needed
    email      VARCHAR(120)
);
```

> `CHAR(10)` storing `'hi'` uses 10 bytes (padded to `'hi        '`). `VARCHAR(10)` storing `'hi'` uses 3 bytes.

---

## 14. GROUP BY vs PARTITION BY

| | GROUP BY | PARTITION BY |
|---|---|---|
| **Effect on rows** | Collapses rows into one per group | Keeps all original rows |
| **Used with** | Aggregate functions in SELECT | Window functions (OVER clause) |
| **Output** | Fewer rows than input | Same number of rows as input |

```sql
-- GROUP BY: one row per department, collapses
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;

-- PARTITION BY: every employee row kept, avg shown per department
SELECT name, dept_id, salary,
       AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg_salary
FROM employees;
```

> Think of `PARTITION BY` as "GROUP BY but without collapsing the rows."

---

## 15. Correlated vs Non-Correlated Subquery

| | Non-Correlated Subquery | Correlated Subquery |
|---|---|---|
| **Dependency** | Independent of the outer query — runs once | References the outer query — runs once per outer row |
| **Performance** | Faster (single execution) | Slower (N executions for N rows) |
| **Readable as** | A standalone query | Cannot run without the outer query |

```sql
-- Non-correlated: inner query runs ONCE, result is used for all outer rows
SELECT name FROM employees
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'Bangalore');

-- Correlated: inner query runs ONCE PER EMPLOYEE ROW
SELECT name, salary
FROM employees e1
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.dept_id = e1.dept_id   -- references e1 from outer query
);
-- "Find employees earning more than their department's average salary"
```

> Correlated subqueries are powerful but expensive. Replace with window functions or JOINs on large datasets for better performance.

---

## Quick Memory Card

| Question | One-line Answer |
|---|---|
| DELETE vs TRUNCATE | DELETE = row-by-row, rollback-able; TRUNCATE = page drop, auto-commit, faster |
| WHERE vs HAVING | WHERE = before grouping; HAVING = after grouping, for aggregates |
| INNER vs LEFT JOIN | INNER = only matches; LEFT = all left rows + NULLs for non-matches |
| UNION vs UNION ALL | UNION removes duplicates; UNION ALL keeps them (faster) |
| RANK vs DENSE_RANK | RANK has gaps after ties; DENSE_RANK does not |
| PRIMARY KEY vs UNIQUE | PK = one per table, no NULLs; UNIQUE = multiple allowed, one NULL |
| EXISTS vs IN | IN evaluates all; EXISTS short-circuits; NOT IN breaks with NULLs |
| CTE vs Subquery | CTE = named, readable, reusable; Subquery = inline, less readable |
| COMMIT vs ROLLBACK | COMMIT = save permanently; ROLLBACK = undo since last commit |
| Clustered vs Non-clustered | Clustered = data physically sorted (one per table); Non-clustered = pointer index |
| View vs Mat. View | View = always fresh (re-runs query); Mat. View = stored, may be stale |
| CHAR vs VARCHAR | CHAR = fixed width padded; VARCHAR = variable, efficient |
| GROUP BY vs PARTITION BY | GROUP BY collapses rows; PARTITION BY keeps all rows |
| Correlated vs Non-correlated | Correlated runs per outer row (slow); Non-correlated runs once (fast) |
