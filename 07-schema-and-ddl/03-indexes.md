# Indexes — The Speed Engine Behind Every Fast Query

> **Interview Priority**: 🔴 Must Know

## What Is It?

An **index** is a separate data structure that the database maintains alongside a table to make lookups faster — exactly like the index at the back of a textbook. Instead of scanning every page (row) to find a topic (value), you jump straight to the right page number.

Without an index, a query like `WHERE emp_id = 42` on a 10-million-row table forces the database to read every single row — a **full table scan**. With an index on `emp_id`, it jumps directly to the matching row in microseconds.

The trade-off: indexes speed up **reads** but slow down **writes** (INSERT, UPDATE, DELETE), because the index structure must be updated every time data changes.

---

## Syntax

```sql
-- Create a basic index
CREATE INDEX idx_name ON table_name (column_name);

-- Create a unique index (also enforces uniqueness constraint)
CREATE UNIQUE INDEX idx_name ON table_name (column_name);

-- Composite index (multi-column)
CREATE INDEX idx_name ON table_name (col1, col2, col3);

-- Drop an index
DROP INDEX idx_name;                            -- PostgreSQL
DROP INDEX idx_name ON table_name;              -- MySQL

-- Check if index is used (MySQL)
EXPLAIN SELECT ...;
EXPLAIN FORMAT=JSON SELECT ...;

-- Check if index is used (PostgreSQL)
EXPLAIN SELECT ...;
EXPLAIN ANALYZE SELECT ...;    -- also actually runs the query and shows real timings

-- View existing indexes on a table
SHOW INDEX FROM employees;                      -- MySQL
\d employees                                    -- PostgreSQL (in psql)
SELECT * FROM pg_indexes WHERE tablename = 'employees';  -- PostgreSQL SQL
```

---

## Key Concepts

### How B-Tree Indexes Work (Conceptually)

The default index type in almost every database (MySQL InnoDB, PostgreSQL) is a **B-Tree (Balanced Tree)**:

```
                     [salary: 75000]
                    /               \
         [salary: 62000]         [salary: 85000]
         /         \             /              \
  [62000→Priya] [74000→Zara] [78000→Dev]  [85000→Aman]
                                               ...
```

- The tree is always balanced — every leaf is the same depth.
- Each node contains sorted keys + pointers to child nodes or actual rows.
- A search is `O(log n)` — for 1 million rows, that's about 20 comparisons instead of 1,000,000.
- The leaf nodes form a **linked list**, enabling efficient range queries (`BETWEEN`, `>`, `<`).

**Primary Key index (Clustered Index — MySQL InnoDB):**
- The table data itself is physically sorted and stored by the primary key.
- There is exactly one clustered index per table.
- Secondary indexes store the primary key value in their leaf nodes (not the row pointer directly).

**Secondary (Non-Clustered) Index:**
- A separate structure that points to the location of rows.
- Multiple secondary indexes can exist on one table.

---

### Index Selectivity

**Selectivity** = the ratio of distinct values to total rows. A highly selective index filters out many rows quickly.

| Column | Distinct Values | Rows | Selectivity | Index Worth It? |
|---|---|---|---|---|
| `emp_id` (PK) | 1000 | 1000 | 100% | ✅ Perfect |
| `email` | 1000 | 1000 | 100% | ✅ Yes |
| `salary` | 900 | 1000 | 90% | ✅ Yes |
| `dept_id` | 4 | 1000 | 0.4% | ❌ Low selectivity |
| `status` in orders | 3 values | 1M | 0.0003% | ❌ Avoid |
| `is_active` (bool) | 2 | 1M | 0.0002% | ❌ Never |

**Rule:** Index columns with **high cardinality** (many distinct values). Skip columns like boolean flags, gender, status enums, etc.

---

### Composite Index Column Order

The order of columns in a composite index is critical. An index on `(dept_id, salary)` can be used for:
- `WHERE dept_id = 10` ✅
- `WHERE dept_id = 10 AND salary > 70000` ✅
- `WHERE dept_id = 10 ORDER BY salary` ✅
- `WHERE salary > 70000` ❌ (left-most column not used → index skipped)

This is called the **left-prefix rule** — the query must use columns from the left side of the composite index first.

---

### Covering Index

A **covering index** includes all columns needed by a query — the database never needs to touch the actual table rows (no "heap fetch"). This is the fastest possible index read.

```sql
-- Query:
SELECT name, salary FROM employees WHERE dept_id = 10;

-- This index covers the query completely:
CREATE INDEX idx_dept_name_salary ON employees (dept_id, name, salary);
-- dept_id satisfies WHERE; name and salary are in the index → zero table lookups
```

---

## When Indexes HELP vs HURT

### ✅ Indexes Help

| Scenario | Reason |
|---|---|
| `WHERE col = value` on high-cardinality column | Direct B-tree lookup |
| `JOIN ON t1.col = t2.col` | Both sides benefit from indexes |
| `ORDER BY col` on an indexed column | Tree is already sorted — avoids file sort |
| `BETWEEN`, `>`, `<` range queries | B-tree leaf list enables efficient range scans |
| Unique constraint enforcement | Index is required internally |
| `GROUP BY col` | Pre-sorted data eliminates sort step |

### ❌ Indexes Hurt or Are Ignored

| Scenario | Reason |
|---|---|
| `INSERT`, `UPDATE`, `DELETE` | Every write must update every relevant index |
| Low-cardinality columns (`status`, `is_active`) | DB prefers full scan — index overhead not worth it |
| Too many indexes on one table | Write penalty compounds; optimizer confusion |
| Function on indexed column | `WHERE UPPER(email) = 'AMAN@...'` — index bypassed |
| Leading wildcard `LIKE '%xyz'` | Can't use B-tree (no left anchor); `LIKE 'xyz%'` is fine |
| Implicit type conversion | `WHERE emp_id = '42'` (string vs int) — index skipped |
| Very small tables | Full scan may be faster than index overhead |
| Frequently updated columns | Constant index restructuring kills write throughput |

---

## Examples

### 1. Index on a high-cardinality column

```sql
-- Queries frequently filter by email — add an index
CREATE UNIQUE INDEX idx_emp_email ON employees (email);

-- Now this query is near-instant even on millions of rows:
SELECT * FROM employees WHERE email = 'aman@company.com';
```

### 2. Composite index for a common query pattern

```sql
-- Common query: filter by dept, order by salary
SELECT name, salary
FROM employees
WHERE dept_id = 10
ORDER BY salary DESC;

-- Without index: full table scan + sort
-- With composite index:
CREATE INDEX idx_dept_salary ON employees (dept_id, salary);
-- dept_id used for WHERE; salary already sorted in index → no file sort
```

### 3. Covering index — eliminates table lookups entirely

```sql
-- This query only needs dept_id, name, and salary:
SELECT name, salary
FROM employees
WHERE dept_id = 10;

-- A covering index includes all three columns:
CREATE INDEX idx_covering_dept ON employees (dept_id, name, salary);

-- EXPLAIN output will show "Using index" (MySQL) or "Index Only Scan" (PostgreSQL)
-- — meaning zero reads from the actual table rows
```

### 4. Index on orders for JOIN performance

```sql
-- This join is common:
SELECT o.order_id, c.name, o.amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed';

-- Index on FK column (critical for JOIN performance):
CREATE INDEX idx_orders_customer_id ON orders (customer_id);

-- Index on status + amount for filtered aggregations:
CREATE INDEX idx_orders_status ON orders (status, amount);
```

### 5. Index that WON'T be used — function on column

```sql
-- ❌ Index on salary is IGNORED — YEAR() wraps the column
SELECT * FROM employees WHERE YEAR(hire_date) = 2022;

-- ✅ Rewrite to let the index work:
SELECT * FROM employees
WHERE hire_date BETWEEN '2022-01-01' AND '2022-12-31';
```

### 6. Index that WON'T be used — leading wildcard

```sql
-- ❌ Leading wildcard — index on product_name is useless
SELECT * FROM products WHERE product_name LIKE '%phone%';

-- ✅ Trailing wildcard — index CAN be used
SELECT * FROM products WHERE product_name LIKE 'Samsung%';
```

### 7. EXPLAIN to verify index usage (MySQL)

```sql
EXPLAIN
SELECT * FROM employees WHERE dept_id = 10 AND salary > 70000;

-- Output columns to focus on:
-- type:         'ref' or 'range' = index used ✅; 'ALL' = full scan ❌
-- key:          name of the index being used
-- rows:         estimated rows scanned (lower is better)
-- Extra:        'Using index' = covering index; 'Using filesort' = no index for ORDER BY
```

```
+----+-------+------+---------+-------------------+------+-------+
| id | type  | key  | key_len | ref               | rows | Extra |
+----+-------+------+---------+-------------------+------+-------+
|  1 | ref   | idx_dept_salary | 4   | const       |   2  | NULL  |
+----+-------+------+---------+-------------------+------+-------+
```

### 8. EXPLAIN ANALYZE (PostgreSQL) — real execution stats

```sql
EXPLAIN ANALYZE
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 80000;

-- Output includes:
-- Index Scan using idx_emp_salary on employees  (actual time=0.02..0.04 rows=2 loops=1)
-- vs
-- Seq Scan on employees  (actual time=0.10..0.80 rows=5 loops=1)
```

### 9. DROP INDEX

```sql
-- MySQL
DROP INDEX idx_dept_salary ON employees;

-- PostgreSQL
DROP INDEX idx_dept_salary;
DROP INDEX IF EXISTS idx_dept_salary;
```

### 10. Partial Index (PostgreSQL) — index only a subset of rows

```sql
-- Only index completed orders (saves space, faster to maintain)
CREATE INDEX idx_completed_orders
ON orders (customer_id, amount)
WHERE status = 'Completed';

-- This index is only used when the query also filters WHERE status = 'Completed'
```

---

## What Columns Should You Index?

### ✅ Good index candidates
- **Primary keys** — auto-created by most databases
- **Foreign keys** — JOIN columns (`dept_id`, `customer_id`, `product_id`)
- **Columns in WHERE clauses** that have high cardinality (`email`, `salary`, `hire_date`)
- **Columns in ORDER BY / GROUP BY** that appear in frequent queries
- **Columns used in range queries** (`BETWEEN`, `>`, `<`)

### ❌ Bad index candidates
- Low-cardinality columns (`status`, `is_active`, `gender`, `dept_id` if only 4 departments)
- Columns that are rarely queried
- Columns in tables with very few rows (< ~1000 rows — full scans are fine)
- Columns that are updated extremely frequently (constant index churn)
- Very wide columns (long VARCHAR) — index nodes become large; use prefix indexes instead

---

## Interview Tips

1. **"What is a B-Tree index and why is it the default?"** — B-Trees support equality (`=`), range (`>`, `<`, `BETWEEN`), and sorted access efficiently. They stay balanced automatically. Hash indexes are faster for equality-only but can't do ranges.

2. **"What is the left-prefix rule for composite indexes?"** — A composite index on `(A, B, C)` is used when the query filters on `A`, or `A+B`, or `A+B+C` — but NOT on `B` or `C` alone. Always put the most selective/filtered column first.

3. **"Why does `WHERE UPPER(email) = 'X'` not use an index?"** — The function wraps the column, so the database evaluates the expression for every row rather than looking it up in the B-tree. Fix: store pre-normalized data, or use a **function-based index** (`CREATE INDEX ON employees (UPPER(email))`).

4. **"What is a covering index?"** — An index that contains all columns the query needs. The engine reads only the index, never touching the actual table rows. It shows as "Using index" (MySQL) or "Index Only Scan" (PostgreSQL) in EXPLAIN output — the gold standard for read performance.

5. **"When should you NOT add an index?"** — On low-cardinality columns (boolean, status enum), on tables with very few rows, on heavily write-loaded tables (each write updates every index), or when you already have too many indexes (the optimizer picks the wrong one). More indexes ≠ more speed.

---

## ❓ Practice Questions

1. The following query runs slowly on a `orders` table with 10 million rows. Write the ideal `CREATE INDEX` statement to speed it up, and explain your column-ordering choice:
   ```sql
   SELECT order_id, amount FROM orders
   WHERE customer_id = 101 AND status = 'Completed'
   ORDER BY order_date DESC;
   ```

2. A developer adds an index on the `status` column of the `orders` table (which has values: `'Pending'`, `'Completed'`, `'Cancelled'`). Explain why this index will likely be ignored by the query optimizer, and what concept this relates to.

3. The query `SELECT name, salary FROM employees WHERE dept_id = 10` is run thousands of times per second. Design a covering index for it. Then explain what "Index Only Scan" (PostgreSQL) or "Using index" (MySQL) means in the EXPLAIN output.

4. Write the SQL to use `EXPLAIN` (MySQL or PostgreSQL — pick one) to check whether the query `SELECT * FROM performance WHERE emp_id = 3 AND year = 2023` uses an index. What column in the EXPLAIN output tells you this, and what value indicates a full table scan?

5. Given that `employees.hire_date` is indexed, explain why the following two queries have different performance. Rewrite the slow one to use the index:
   ```sql
   -- Query A:
   SELECT * FROM employees WHERE YEAR(hire_date) = 2021;
   -- Query B:
   SELECT * FROM employees WHERE hire_date >= '2021-01-01' AND hire_date < '2022-01-01';
   ```
