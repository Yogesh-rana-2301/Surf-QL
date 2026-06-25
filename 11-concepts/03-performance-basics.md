# SQL Query Performance — Writing Faster Queries

> **Interview Priority**: 🔴 Must Know

## What Is It?

Query optimization is about writing SQL that returns correct results **as fast as possible**. Interviewers ask this to test real-world SQL maturity — anyone can write correct SQL, but good engineers write *efficient* SQL.

---

## Key Concepts & Actionable Tips

### 1. Avoid `SELECT *` — Specify Only Needed Columns

```sql
-- ❌ Fetches all columns — wastes I/O and memory
SELECT * FROM employees;

-- ✅ Fetch only what you need
SELECT emp_id, name, salary FROM employees;
```

Why it matters: Unnecessary columns consume I/O bandwidth, can't use covering indexes, and make query plans harder to optimize.

---

### 2. Filter Early — Use Indexed Columns in WHERE

```sql
-- ✅ If dept_id is indexed, this is fast
SELECT name, salary
FROM employees
WHERE dept_id = 10;

-- ❌ Non-selective filter scans the whole table
SELECT name, salary
FROM employees
WHERE salary > 0;   -- almost all rows pass — index barely helps
```

The optimizer uses indexes best when you filter on **high-cardinality, indexed columns** early.

---

### 3. Never Wrap Indexed Columns in Functions in WHERE

```sql
-- ❌ Index on hire_date is NOT used — function applied first
SELECT name FROM employees
WHERE YEAR(hire_date) = 2022;

-- ✅ Rewrite to use the index directly
SELECT name FROM employees
WHERE hire_date >= '2022-01-01'
  AND hire_date <  '2023-01-01';
```

Same trap with: `UPPER(email) = 'X'`, `LENGTH(name) > 5`, `DATE(created_at) = '2024-01-01'`.

---

### 4. Avoid Leading Wildcard in LIKE

```sql
-- ❌ Leading % means full table scan — index on name is useless
SELECT name FROM employees WHERE name LIKE '%aman%';

-- ✅ Trailing wildcard CAN use an index
SELECT name FROM employees WHERE name LIKE 'Aman%';
```

If you must search inside strings, consider full-text indexes (`FULLTEXT INDEX` in MySQL, `GIN` in PostgreSQL).

---

### 5. Prefer JOINs Over Correlated Subqueries

```sql
-- ❌ Correlated subquery: runs once per row in employees — O(n²)
SELECT e.name, e.salary
FROM employees e
WHERE e.salary > (
  SELECT AVG(salary)
  FROM employees
  WHERE dept_id = e.dept_id
);

-- ✅ Rewrite with JOIN + GROUP BY — runs aggregation once
WITH dept_avg AS (
  SELECT dept_id, AVG(salary) AS avg_sal
  FROM employees
  GROUP BY dept_id
)
SELECT e.name, e.salary
FROM employees e
JOIN dept_avg d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_sal;
```

---

### 6. Use EXISTS Instead of IN for Large Subquery Results

```sql
-- ❌ IN materializes the entire subquery result set
SELECT name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- ✅ EXISTS short-circuits as soon as it finds one match
SELECT name FROM customers c
WHERE EXISTS (
  SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
```

**Critical trap**: `NOT IN` returns **no rows at all** if the subquery returns any NULL. Prefer `NOT EXISTS`.

```sql
-- ❌ If orders.customer_id has any NULL → entire NOT IN returns empty!
SELECT name FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders);

-- ✅ Safe
SELECT name FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
```

---

### 7. Use LIMIT When You Only Need Top N Rows

```sql
-- ❌ Sorts everything, returns everything
SELECT name, salary FROM employees ORDER BY salary DESC;

-- ✅ Stop after finding first 5
SELECT name, salary FROM employees ORDER BY salary DESC LIMIT 5;
```

---

### 8. Keep Transactions Short — Reduce Lock Duration

Long transactions hold locks, blocking other queries. Minimize work inside a transaction:

```sql
-- ❌ Don't do heavy reads inside a write transaction
BEGIN;
  SELECT ... (slow complex query);
  UPDATE employees SET salary = salary * 1.1 WHERE dept_id = 10;
COMMIT;

-- ✅ Do the computation before the transaction
-- (pre-compute what you need, then open transaction only for the write)
BEGIN;
  UPDATE employees SET salary = salary * 1.1 WHERE dept_id = 10;
COMMIT;
```

---

### 9. Composite Index — Column Order Matters (Leftmost Prefix Rule)

```sql
CREATE INDEX idx_emp_dept_salary ON employees (dept_id, salary);
```

This index helps:
- `WHERE dept_id = 10` ✅
- `WHERE dept_id = 10 AND salary > 70000` ✅
- `WHERE dept_id = 10 ORDER BY salary` ✅

This index does NOT help:
- `WHERE salary > 70000` ❌ (skips the leading column `dept_id`)
- `ORDER BY salary` alone ❌

Rule: Put the **most selective filter column first**, or the column used most in WHERE conditions.

---

### 10. Avoid Implicit Type Conversions in WHERE

```sql
-- employees.emp_id is INT, but you pass a string
-- ❌ Database must cast every emp_id to VARCHAR to compare → index not used
SELECT * FROM employees WHERE emp_id = '5';

-- ✅ Match the data type
SELECT * FROM employees WHERE emp_id = 5;
```

---

### 11. Use EXPLAIN / EXPLAIN ANALYZE to Diagnose

```sql
-- See the query plan (estimates)
EXPLAIN
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 70000;

-- See actual runtime stats (PostgreSQL)
EXPLAIN ANALYZE
SELECT ...;
```

**What to look for**:
- `Seq Scan` on a large table → missing index
- `Nested Loop` on large tables → possible performance issue
- High `rows` estimate but low actual → stale statistics (run `ANALYZE`)
- Index Scan → good, index is being used

---

## Quick Reference Checklist

| Tip | Rule |
|---|---|
| Column selection | Use specific columns, not `SELECT *` |
| Filter columns | Use indexed columns in WHERE |
| Functions in WHERE | Never on indexed columns |
| LIKE patterns | Avoid leading `%` |
| Subqueries | Prefer JOIN or CTE over correlated subquery |
| EXISTS vs IN | Use EXISTS for large sets; `NOT EXISTS` instead of `NOT IN` |
| LIMIT | Always add when you only need top N |
| Transactions | Keep short; minimize work inside BEGIN/COMMIT |
| Composite index | Leading column must match WHERE condition |
| Data types | Match parameter type to column type |
| Diagnosis | Always EXPLAIN before optimizing |

---

## Interview Tips

1. **"Optimize this query"** — always start with: check if WHERE columns are indexed, check for `SELECT *`, check for function on indexed column
2. **EXPLAIN output** — knowing what `Seq Scan` vs `Index Scan` means scores huge points
3. **NOT IN vs NOT EXISTS** — the NULL trap is a classic gotcha question
4. **Composite index order** — interviewers love asking "will this index help for this query?"
5. **Correlated subquery** — explain why it's slow and show the CTE rewrite

---

## ❓ Practice Questions

1. The following query is slow on a table with 5 million rows. Identify at least 3 performance issues and rewrite it:
   ```sql
   SELECT * FROM employees WHERE UPPER(name) = 'AMAN' AND YEAR(hire_date) = 2022;
   ```

2. You have `CREATE INDEX idx_dept_sal ON employees(dept_id, salary)`. Which of these queries will use the index?
   - `WHERE dept_id = 10`
   - `WHERE salary > 80000`
   - `WHERE dept_id = 10 AND salary > 80000`
   - `ORDER BY salary DESC`

3. Rewrite this correlated subquery using a CTE for better performance:
   ```sql
   SELECT emp_id, name FROM employees e
   WHERE salary > (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id);
   ```

4. A query using `NOT IN (SELECT customer_id FROM orders)` returns 0 rows even though you know many customers have no orders. What could be wrong and how do you fix it?

5. When would you recommend adding an index on the `status` column of the `orders` table? When would you NOT recommend it?
