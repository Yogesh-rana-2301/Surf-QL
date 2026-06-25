# LIMIT & OFFSET — Paginating Query Results

> **Interview Priority**: 🔴 Must Know

## What Is It?

`LIMIT` restricts how many rows a query returns. `OFFSET` skips a specified number of rows before starting to return results. Together they implement **pagination** — retrieving data one "page" at a time instead of dumping every row at once. SQL Server uses `TOP` (older) and `FETCH NEXT` (standard); PostgreSQL and MySQL use `LIMIT/OFFSET`.

## Syntax

```sql
-- MySQL / PostgreSQL
SELECT columns
FROM table
ORDER BY column
LIMIT  <row_count>
OFFSET <rows_to_skip>;

-- SQL Standard (PostgreSQL, Oracle 12c+, SQL Server 2012+)
SELECT columns
FROM table
ORDER BY column
OFFSET <rows_to_skip> ROWS
FETCH NEXT <row_count> ROWS ONLY;

-- SQL Server (legacy)
SELECT TOP (n) columns
FROM table
ORDER BY column;

-- SQL Server TOP with percentage
SELECT TOP (10) PERCENT columns
FROM table
ORDER BY salary DESC;
```

## Key Concepts

- **Always pair with ORDER BY**: Without `ORDER BY`, the rows returned by `LIMIT/OFFSET` are non-deterministic — you may get different rows on each execution. This is a classic interview gotcha.
- **OFFSET is 0-based**: `OFFSET 0` means "skip nothing" (return from the very first qualifying row).
- **Page formula**: For page number `P` (1-indexed) with page size `N`, the offset is `(P - 1) * N`.
- **Performance degrades at large offsets**: `OFFSET 1000000 LIMIT 10` still makes the database scan and discard 1 000 000 rows. Use **keyset / cursor-based pagination** for large datasets.
- **FETCH NEXT ... ROWS ONLY** is the SQL-standard syntax introduced in SQL:2008. Prefer it for portability.
- **MySQL shorthand**: `LIMIT offset, count` (e.g., `LIMIT 10, 5`) — note the reversed argument order vs. the `LIMIT count OFFSET offset` form. This trips people up.
- **TOP in SQL Server** does not support an `OFFSET`; use `OFFSET…FETCH` for pagination in SQL Server.
- **DISTINCT + LIMIT**: The DISTINCT operation happens first, then LIMIT is applied to the deduplicated set.

## Examples

### Setup reference — employees sorted by salary

| emp_id | name  | salary |
|--------|-------|--------|
| 2      | Priya | 62000  |
| 4      | Zara  | 74000  |
| 5      | Dev   | 78000  |
| 1      | Aman  | 85000  |
| 3      | Ravi  | 91000  |

Page size = 2. Five employees → 3 pages.

---

### 1 — Top 3 highest-paid employees (MySQL / PostgreSQL)

```sql
SELECT emp_id, name, salary
FROM employees
ORDER BY salary DESC
LIMIT 3;

-- Returns: Ravi (91000), Aman (85000), Dev (78000)
```

### 2 — Page 1 (first 2 employees by salary ascending)

```sql
SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC
LIMIT 2 OFFSET 0;

-- Returns: Priya (62000), Zara (74000)
```

### 3 — Page 2 (skip 2, fetch next 2)

```sql
SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC
LIMIT 2 OFFSET 2;

-- Returns: Dev (78000), Aman (85000)
```

### 4 — Page 3 (skip 4, fetch remaining)

```sql
SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC
LIMIT 2 OFFSET 4;

-- Returns: Ravi (91000)
```

### 5 — SQL Standard FETCH NEXT (PostgreSQL / SQL Server 2012+)

```sql
-- Page 1
SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC
OFFSET 0 ROWS
FETCH NEXT 2 ROWS ONLY;

-- Page 2
SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC
OFFSET 2 ROWS
FETCH NEXT 2 ROWS ONLY;
```

### 6 — SQL Server legacy TOP

```sql
-- Top 3 highest-paid (SQL Server)
SELECT TOP (3) emp_id, name, salary
FROM employees
ORDER BY salary DESC;
```

### 7 — MySQL shorthand (LIMIT offset, count) — be careful!

```sql
-- LIMIT 2, 2 means: skip 2 rows, then return 2 rows (same as LIMIT 2 OFFSET 2)
SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC
LIMIT 2, 2;

-- Returns: Dev (78000), Aman (85000)
```

### 8 — Dynamic pagination using a parameter (application-side)

```sql
-- For page P with page size N:
-- OFFSET = (P - 1) * N
-- Example: page 3, page size 2 → OFFSET 4

SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC
LIMIT 2 OFFSET 4;
```

### 9 — Keyset (cursor-based) pagination — scalable alternative

```sql
-- Instead of OFFSET, remember the last salary seen (e.g., 78000)
-- and filter: fetch next rows strictly after that value
SELECT emp_id, name, salary
FROM employees
WHERE salary > 78000         -- "cursor" from the previous page's last row
ORDER BY salary ASC
LIMIT 2;

-- Returns: Aman (85000), Ravi (91000)
-- No skipped-row scan; scales to millions of rows
```

## Syntax Comparison Table

| Feature | MySQL | PostgreSQL | SQL Server |
|---|---|---|---|
| Basic limit | `LIMIT n` | `LIMIT n` | `TOP (n)` / `FETCH NEXT n ROWS ONLY` |
| With offset | `LIMIT n OFFSET m` | `LIMIT n OFFSET m` | `OFFSET m ROWS FETCH NEXT n ROWS ONLY` |
| Shorthand | `LIMIT m, n` | ✗ | ✗ |
| SQL standard | Partial | Full support | Full support (2012+) |
| Percent | ✗ | ✗ | `TOP (n) PERCENT` |

## Interview Tips

1. **"What happens if you use LIMIT without ORDER BY?"** — The answer is the database returns an *arbitrary* set of rows; the result is not reproducible. Always stress this.
2. **Large OFFSET performance** — Interviewers love this. `OFFSET 100000 LIMIT 10` scans 100,010 rows and discards 100,000. Keyset pagination avoids this by filtering on the last-seen key value.
3. **MySQL `LIMIT offset, count` vs `LIMIT count OFFSET offset`** — The argument order is swapped. Many candidates mix these up; be precise.
4. **"How do you get the Nth highest salary?"** — A classic: `ORDER BY salary DESC LIMIT 1 OFFSET N-1`. Know this pattern.
5. **SQL Server**: `TOP` alone cannot paginate (no OFFSET). For pagination in SQL Server use `OFFSET … FETCH NEXT … ROWS ONLY` inside `ORDER BY`.

## ❓ Practice Questions

1. Write a query to find the **3rd highest salary** among all employees using `LIMIT` and `OFFSET`. (Return only that one row.)

2. Implement pagination over the `orders` table sorted by `order_date` descending. Write queries for **page 1** and **page 3**, with a page size of 5.

3. Write the equivalent of `LIMIT 10 OFFSET 20` using the SQL-standard `OFFSET … FETCH NEXT` syntax.

4. A product catalogue (`products` table) has thousands of rows. Explain why `LIMIT 10 OFFSET 50000` is slow and rewrite it using **keyset pagination** assuming you remember the last `product_id` seen was 50020.

5. Write a SQL Server query using `TOP` to retrieve the **top 5 most expensive products** by `price` from the `products` table. Then rewrite it using `OFFSET … FETCH NEXT` for pagination (page 1, 5 rows).
