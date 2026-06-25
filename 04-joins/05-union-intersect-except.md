# UNION, INTERSECT & EXCEPT — Combining Result Sets Vertically

> **Interview Priority**: 🔴 Must Know

---

## What Is It?

**Set operators** combine the results of two or more `SELECT` statements **vertically** (stacking rows) rather than horizontally (like joins). The three core operators are:

- **`UNION`** — All rows from both queries, **duplicates removed**
- **`UNION ALL`** — All rows from both queries, **duplicates kept** (faster)
- **`INTERSECT`** — Only rows that appear in **both** queries
- **EXCEPT** / **MINUS** — Rows from the **first query** that do **not** appear in the second

These are fundamentally different from JOINs: JOINs add columns; set operators add rows.

---

## Syntax

```sql
-- UNION: deduplicated combination
SELECT col1, col2 FROM table_a
UNION
SELECT col1, col2 FROM table_b;

-- UNION ALL: all rows, including duplicates (faster — no dedup step)
SELECT col1, col2 FROM table_a
UNION ALL
SELECT col1, col2 FROM table_b;

-- INTERSECT: rows common to both
SELECT col1, col2 FROM table_a
INTERSECT
SELECT col1, col2 FROM table_b;

-- EXCEPT (PostgreSQL, SQL Server, SQLite): rows in A but not B
SELECT col1, col2 FROM table_a
EXCEPT
SELECT col1, col2 FROM table_b;

-- MINUS (Oracle): same as EXCEPT
SELECT col1, col2 FROM table_a
MINUS
SELECT col1, col2 FROM table_b;
```

---

## Rules — All Set Operators

> [!IMPORTANT]
> All set operators require both SELECT statements to follow the same structural rules:

1. **Same number of columns**: Both queries must return the same number of columns in the SELECT list.
2. **Compatible data types**: Corresponding columns must have compatible (implicitly castable) types. Column 1 in query A and Column 1 in query B must be comparable.
3. **Column names from the first query**: The column names (aliases) in the final result set are taken from the **first** SELECT statement.
4. **ORDER BY applies to the final result**: You can only have one `ORDER BY` clause, and it goes after the last SELECT. It references columns from the final result (i.e., the first query's names).
5. **NULL handling**: NULLs are treated as equal to each other for deduplication/comparison purposes in INTERSECT and EXCEPT (unlike `NULL = NULL` in WHERE which is false).

---

## UNION vs UNION ALL — The Performance Decision

| | UNION | UNION ALL |
|---|---|---|
| Deduplication | ✅ Yes — removes duplicates | ❌ No — keeps all rows |
| Performance | Slower (sort/hash to dedup) | Faster (no extra step) |
| Memory | Higher (intermediate result sorting) | Lower |
| Use when | You need unique rows across both sets | You know rows are distinct OR don't care about duplicates |
| Common mistake | Using UNION when UNION ALL is sufficient | Using UNION ALL when UNION is semantically needed |

> **Rule of thumb**: Default to `UNION ALL` for performance. Explicitly use `UNION` only when deduplication is semantically required.

---

## Database Support

| Operator | MySQL | PostgreSQL | SQL Server | Oracle | SQLite |
|---|---|---|---|---|---|
| `UNION` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `UNION ALL` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `INTERSECT` | ✅ (8.0.31+) | ✅ | ✅ | ✅ | ✅ (3.0+) |
| `EXCEPT` | ✅ (8.0.31+) | ✅ | ✅ | ❌ | ✅ (3.0+) |
| `MINUS` | ❌ | ❌ | ❌ | ✅ | ❌ |

> **MySQL note**: Before version 8.0.31, MySQL did **not** support `INTERSECT` or `EXCEPT`. Use `INNER JOIN` (for INTERSECT) and `LEFT JOIN IS NULL` (for EXCEPT) as workarounds in older MySQL versions.

---

## Examples

### Example 1 — UNION: Combine Employee Names and Customer Names (All People)

```sql
-- Get a unified list of all people in the system (employees + customers)
SELECT
    emp_id      AS person_id,
    name,
    email,
    'Employee'  AS person_type
FROM employees

UNION

SELECT
    customer_id AS person_id,
    name,
    email,
    'Customer'  AS person_type
FROM customers;
```

**Sample Output:**

```
person_id | name          | email                      | person_type
----------|---------------|----------------------------|------------
1         | Aman          | aman@company.com           | Employee
2         | Priya         | priya@company.com          | Employee
3         | Ravi          | ravi@company.com           | Employee
4         | Zara          | zara@company.com           | Employee
5         | Dev           | dev@company.com            | Employee
1         | Arjun Mehta   | arjun@example.com          | Customer
2         | Sneha Patel   | sneha@example.com          | Customer
...
```

> `UNION` is used here because both queries are structurally distinct (employees vs customers), so there are no cross-table duplicates in practice. Still, using `UNION ALL` would be slightly faster if you're certain there are no overlapping rows.

---

### Example 2 — UNION ALL: Combine Sales Amounts from Two Periods

```sql
-- Revenue report combining Q1 and Q2 orders into one dataset
SELECT
    customer_id,
    amount,
    order_date,
    'Q1-2024' AS quarter
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31'

UNION ALL

SELECT
    customer_id,
    amount,
    order_date,
    'Q2-2024' AS quarter
FROM orders
WHERE order_date BETWEEN '2024-04-01' AND '2024-06-30';
```

> `UNION ALL` is correct here — the same order can't exist in both Q1 and Q2, so deduplication is unnecessary. Using plain `UNION` would waste CPU on pointless comparison.

---

### Example 3 — INTERSECT: Customers Who Have Ordered AND Are in a Specific City

```sql
-- Customers from Mumbai who have placed at least one order
SELECT customer_id
FROM customers
WHERE city = 'Mumbai'

INTERSECT

SELECT customer_id
FROM orders;
```

**Sample Output:**

```
customer_id
-----------
1           ← Arjun Mehta (Mumbai, has orders)
```

> This returns `customer_id` values that appear in both result sets. Equivalent to:
> ```sql
> SELECT DISTINCT c.customer_id
> FROM customers c
> INNER JOIN orders o ON c.customer_id = o.customer_id
> WHERE c.city = 'Mumbai';
> ```

---

### Example 4 — EXCEPT: Customers Who Have Never Ordered

```sql
-- Customers in the customers table but NOT in the orders table
SELECT customer_id
FROM customers

EXCEPT

SELECT customer_id
FROM orders;
```

**Sample Output:**

```
customer_id
-----------
4           ← Rohan Desai (no orders)
5           ← Meena Iyer (no orders)
```

> This is equivalent to the LEFT JOIN + IS NULL anti-join pattern:
> ```sql
> SELECT c.customer_id
> FROM customers c
> LEFT JOIN orders o ON c.customer_id = o.customer_id
> WHERE o.order_id IS NULL;
> ```

---

### Example 5 — EXCEPT: Products Never Ordered

```sql
-- Products that appear in the products table but have never been ordered
SELECT product_id, product_name
FROM products

EXCEPT

SELECT DISTINCT p.product_id, p.product_name
FROM products p
INNER JOIN orders o ON p.product_id = o.product_id;
```

> Note: Both SELECT lists must have the same structure. The second query brings in `product_name` by joining back to `products` so the column types match.

---

### Example 6 — UNION with ORDER BY (Applied to Final Result)

```sql
-- All employees and customers with an email, sorted by name
SELECT name, email, 'Employee' AS type FROM employees WHERE email IS NOT NULL
UNION ALL
SELECT name, email, 'Customer' AS type FROM customers WHERE email IS NOT NULL
ORDER BY name ASC;  -- ← ORDER BY goes here, after the last SELECT
```

> You **cannot** put `ORDER BY` inside individual SELECT statements of a UNION. It must appear after the last SELECT and refers to the column names from the **first** SELECT.

---

### Example 7 — Simulating INTERSECT in Older MySQL (Pre-8.0.31)

```sql
-- INTERSECT workaround: customers who are in both tables
-- (customers who have placed at least one order)
SELECT DISTINCT c.customer_id
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id;
```

---

### Example 8 — Simulating EXCEPT in Older MySQL (Pre-8.0.31)

```sql
-- EXCEPT workaround: customers with NO orders
SELECT c.customer_id
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

---

### Example 9 — UNION ALL for Audit Logging (Combining Multiple Event Tables)

```sql
-- Imagine you have order_events_2023 and order_events_2024 as partitioned tables
-- Combine them for a full history without deduplication overhead
SELECT order_id, customer_id, amount, order_date, status FROM orders WHERE YEAR(order_date) = 2023
UNION ALL
SELECT order_id, customer_id, amount, order_date, status FROM orders WHERE YEAR(order_date) = 2024
ORDER BY order_date;
```

---

## Common Mistakes

| Mistake | Explanation |
|---|---|
| Mismatched column count | Both SELECTs must have the same number of columns |
| Incompatible types | Can't UNION a VARCHAR column with an INT column without casting |
| Using UNION when UNION ALL is faster | If rows are structurally unique, UNION ALL is always better |
| ORDER BY inside a subquery | `ORDER BY` must be the final clause after all UNION/INTERSECT/EXCEPT operations |
| Expecting INTERSECT to work in old MySQL | Not supported before MySQL 8.0.31 |
| Using MINUS in non-Oracle databases | Only Oracle uses `MINUS`; use `EXCEPT` everywhere else |

---

## Interview Tips

1. **"What's the difference between UNION and UNION ALL?"** — `UNION` removes duplicates (requires an extra sort/hash step); `UNION ALL` keeps all rows and is faster. Use `UNION ALL` unless deduplication is explicitly needed.

2. **"What are the rules for using UNION?"** — Same number of columns, compatible data types, column names from the first SELECT, and ORDER BY only at the very end.

3. **"How do you simulate INTERSECT in MySQL?"** — Use `INNER JOIN` between the two datasets on the key column, with `SELECT DISTINCT`.

4. **"How do you simulate EXCEPT in MySQL?"** — Use `LEFT JOIN ... WHERE right_col IS NULL` (Anti-Join pattern).

5. **"Is UNION the same as a JOIN?"** — No. UNION stacks rows vertically (more rows, same columns). JOINs expand rows horizontally (same rows, more columns). This is a fundamental distinction.

---

## ❓ Practice Questions

1. Write a query using `UNION` to produce a combined list of all employee names and customer names, with a column indicating whether each person is an `'Employee'` or a `'Customer'`.

2. Using `INTERSECT`, find the `customer_id`s of customers who have placed orders AND whose city is `'Bangalore'`. Then write the equivalent query using `INNER JOIN` (to practice the MySQL workaround).

3. Using `EXCEPT`, find all products that have never appeared in any order. Write the equivalent query using `LEFT JOIN ... IS NULL` as a MySQL-compatible alternative.

4. Write a `UNION ALL` query that combines the total order amount by status for the years 2023 and 2024 separately, then adds a grand total row at the bottom. (Hint: You may use `GROUP BY` in each sub-query.)

5. Explain with an example why `ORDER BY` inside a UNION's sub-SELECT is not allowed. What is the correct way to sort the final result of a UNION query?
