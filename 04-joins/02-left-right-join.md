# LEFT & RIGHT JOIN — Keep All Rows from One Side

> **Interview Priority**: 🔴 Must Know

---

## What Is It?

**LEFT OUTER JOIN** (usually written as `LEFT JOIN`) returns **all rows from the left table**, plus matched rows from the right table. Where no match exists in the right table, the right table's columns are filled with `NULL`.

**RIGHT OUTER JOIN** (`RIGHT JOIN`) is the mirror image — it returns **all rows from the right table**, with `NULL`s for unmatched left-table columns.

In practice, **RIGHT JOIN is almost never used**. Every RIGHT JOIN can be rewritten as a LEFT JOIN by simply swapping the table order. This keeps your queries consistent and easier to read.

---

## Syntax

```sql
-- LEFT JOIN
SELECT columns
FROM   left_table  l
LEFT JOIN right_table r
    ON l.key = r.key;

-- RIGHT JOIN (equivalent to the above with tables swapped)
SELECT columns
FROM   right_table r
RIGHT JOIN left_table l
    ON r.key = l.key;

-- LEFT JOIN rewritten to replace RIGHT JOIN
-- RIGHT JOIN: SELECT ... FROM A RIGHT JOIN B ON A.key = B.key
-- Equivalent: SELECT ... FROM B LEFT JOIN  A ON B.key = A.key
```

---

## Key Concepts

- **NULL-filled non-matches**: When a row in the left table has no corresponding row in the right table, every column from the right table appears as `NULL` in that output row.
- **Preserving all rows**: The entire left table is preserved in the output — this is the key difference from INNER JOIN.
- **RIGHT JOIN avoidance**: Swapping table order and using LEFT JOIN produces identical results. Using only LEFT JOIN in a codebase is a widely accepted convention for readability.
- **Detecting non-matches**: Filter on `right_table.primary_key IS NULL` in a `WHERE` clause after a LEFT JOIN to find rows in the left table that have **no match** in the right table. This is an **Anti-Join pattern**.
- **One-to-many behavior**: If a left-table row matches multiple right-table rows, it is duplicated — the same as INNER JOIN. NULL rows are only for zero-match cases.

---

## ⚠️ Critical Interview Concept: `ON` vs `WHERE` in Outer Joins

This is one of the **most frequently asked interview traps** for SQL. The behavior differs fundamentally for OUTER JOINs.

### The Rule:
- **`ON` clause** — filter applied **during the join** (before rows are discarded). For LEFT JOIN, unmatched left rows are still retained, they just get NULLs on the right side.
- **`WHERE` clause** — filter applied **after the join** (on the final result set). Filtering `WHERE right_col = value` eliminates rows where the right side is NULL, which **converts your LEFT JOIN into an INNER JOIN**.

### Demonstration:

**Scenario**: All customers, plus their order amounts — but only for orders where `amount > 2000`.

#### Version A — Filter in `WHERE` (Wrong for outer join intent)

```sql
SELECT
    c.customer_id,
    c.name          AS customer_name,
    o.order_id,
    o.amount
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.amount > 2000;  -- ← This eliminates all NULL rows!
```

**Sample Output — Version A:**

```
customer_id | customer_name | order_id | amount
------------|---------------|----------|--------
1           | Arjun Mehta   | 101      | 2500.00
1           | Arjun Mehta   | 103      | 4200.00
```

> Customers with no orders, and customers whose only orders are ≤ 2000, **disappear entirely** from the result. The LEFT JOIN effectively became an INNER JOIN.

---

#### Version B — Filter in `ON` (Correct for outer join intent)

```sql
SELECT
    c.customer_id,
    c.name          AS customer_name,
    o.order_id,
    o.amount
FROM customers c
LEFT JOIN orders o
    ON  c.customer_id = o.customer_id
    AND o.amount > 2000;  -- ← Applied during join; non-matching right rows = NULL
```

**Sample Output — Version B:**

```
customer_id | customer_name   | order_id | amount
------------|-----------------|----------|--------
1           | Arjun Mehta     | 101      | 2500.00
1           | Arjun Mehta     | 103      | 4200.00
2           | Sneha Patel     | NULL     | NULL
3           | Kavya Nair      | NULL     | NULL
4           | Rohan Desai     | NULL     | NULL
```

> All customers appear. Those with no orders ≥ 2000 (including customers with no orders at all) show up with NULLs on the right side. The LEFT JOIN's promise is kept.

---

### Summary Table — ON vs WHERE

| Scenario | `ON` clause filter | `WHERE` clause filter |
|---|---|---|
| INNER JOIN | Same result | Same result |
| LEFT JOIN — filter right-side column | Retains all left rows; unmatched = NULL | **Drops left rows with no right match** (converts to INNER) |
| LEFT JOIN — filter left-side column | Removes left rows (unusual) | Same as ON for left-side columns |
| LEFT JOIN — find unmatched rows | N/A | Use `WHERE right_col IS NULL` |

---

## Examples

### Example 1 — All Customers, With or Without Orders

```sql
SELECT
    c.customer_id,
    c.name          AS customer_name,
    c.city,
    o.order_id,
    o.amount,
    o.status
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id;
```

**Sample Output:**

```
customer_id | customer_name | city      | order_id | amount  | status
------------|---------------|-----------|----------|---------|----------
1           | Arjun Mehta   | Mumbai    | 101      | 2500.00 | Delivered
1           | Arjun Mehta   | Mumbai    | 103      | 4200.00 | Delivered
2           | Sneha Patel   | Bangalore | 102      | 1800.00 | Shipped
3           | Kavya Nair    | Chennai   | 104      | 950.00  | Pending
4           | Rohan Desai   | Delhi     | NULL     | NULL    | NULL
5           | Meena Iyer    | Hyderabad | NULL     | NULL    | NULL
```

> Rohan Desai and Meena Iyer have never placed an order. They appear with NULLs on the orders side. An INNER JOIN would have excluded them entirely.

---

### Example 2 — Find Customers Who Have Never Ordered (Anti-Join)

```sql
SELECT
    c.customer_id,
    c.name          AS customer_name,
    c.email
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;  -- Right-side PK is NULL → no match → never ordered
```

**Sample Output:**

```
customer_id | customer_name | email
------------|---------------|---------------------
4           | Rohan Desai   | rohan@example.com
5           | Meena Iyer    | meena@example.com
```

> This is one of the most practical real-world queries. Use `IS NULL` on the right table's **primary key** (not a nullable column) to reliably detect non-matches.

---

### Example 3 — All Employees, Including Those Without a Department

```sql
SELECT
    e.emp_id,
    e.name          AS employee_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id;
```

**Sample Output:**

```
emp_id | employee_name | salary   | dept_name   | location
-------|---------------|----------|-------------|----------
1      | Aman          | 85000.00 | Engineering | Bangalore
2      | Priya         | 62000.00 | HR          | Mumbai
3      | Ravi          | 91000.00 | Finance     | Delhi
4      | Zara          | 74000.00 | Marketing   | Bangalore
5      | Dev           | 78000.00 | Engineering | Bangalore
6      | Nisha         | 55000.00 | NULL        | NULL
```

> Nisha has `dept_id = NULL` (or a dept_id that doesn't exist in departments). She appears with NULLs for the department columns — preserved by the LEFT JOIN.

---

### Example 4 — RIGHT JOIN (and Its LEFT JOIN Equivalent)

```sql
-- RIGHT JOIN: all departments, even those with no employees
SELECT
    e.name          AS employee_name,
    d.dept_name,
    d.location
FROM employees e
RIGHT JOIN departments d
    ON e.dept_id = d.dept_id;

-- Equivalent LEFT JOIN (preferred style):
SELECT
    e.name          AS employee_name,
    d.dept_name,
    d.location
FROM departments d
LEFT JOIN employees e
    ON d.dept_id = e.dept_id;
```

**Sample Output (both queries produce the same result):**

```
employee_name | dept_name   | location
--------------|-------------|----------
Aman          | Engineering | Bangalore
Dev           | Engineering | Bangalore
Priya         | HR          | Mumbai
Ravi          | Finance     | Delhi
Zara          | Marketing   | Bangalore
NULL          | Legal       | Hyderabad
```

> The `Legal` department has no employees yet. Using LEFT JOIN with tables swapped gives the same output as RIGHT JOIN.

---

### Example 5 — Count of Orders per Customer (Including Zero-Order Customers)

```sql
SELECT
    c.name                          AS customer_name,
    COUNT(o.order_id)               AS order_count,
    COALESCE(SUM(o.amount), 0)      AS total_spent
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;
```

**Sample Output:**

```
customer_name | order_count | total_spent
--------------|-------------|------------
Arjun Mehta   | 2           | 6700.00
Sneha Patel   | 1           | 1800.00
Kavya Nair    | 1           | 950.00
Rohan Desai   | 0           | 0.00
Meena Iyer    | 0           | 0.00
```

> `COUNT(o.order_id)` counts non-NULL values, so it correctly returns 0 for unmatched rows. `COALESCE(SUM(...), 0)` replaces NULL totals with 0 for cleaner presentation.

---

### Example 6 — ON Clause Filter to Get Only Delivered Orders, Keeping All Customers

```sql
SELECT
    c.name          AS customer_name,
    o.order_id,
    o.amount,
    o.status
FROM customers c
LEFT JOIN orders o
    ON  c.customer_id = o.customer_id
    AND o.status = 'Delivered';  -- Only "Delivered" orders are joined; others → NULL
```

**Sample Output:**

```
customer_name | order_id | amount  | status
--------------|----------|---------|----------
Arjun Mehta   | 101      | 2500.00 | Delivered
Arjun Mehta   | 103      | 4200.00 | Delivered
Sneha Patel   | NULL     | NULL    | NULL
Kavya Nair    | NULL     | NULL    | NULL
Rohan Desai   | NULL     | NULL    | NULL
Meena Iyer    | NULL     | NULL    | NULL
```

> Sneha Patel's `Shipped` order doesn't match the `ON` condition, so she appears with NULLs — but still appears. If the filter were in `WHERE`, she'd disappear entirely.

---

## Interview Tips

1. **ON vs WHERE trap**: The single most important thing to know about outer joins. Filtering a right-side column in `WHERE` silently converts a LEFT JOIN to an INNER JOIN. Always be able to explain this with an example.

2. **"When would you use a LEFT JOIN over INNER JOIN?"** — When you want to preserve all rows from the left table regardless of whether a match exists on the right. Classic use cases: all customers including those with no orders, all employees including those unassigned to a department.

3. **"What does `WHERE right_table.col IS NULL` after a LEFT JOIN do?"** — It gives you an Anti-Join: rows in the left table that have no match in the right table. This is a very common interview coding task.

4. **"Do you ever use RIGHT JOIN?"** — Technically yes, but in practice, every RIGHT JOIN can be rewritten as a LEFT JOIN by swapping table order. Most teams standardize on LEFT JOIN only.

5. **`COUNT(*)` vs `COUNT(col)` with LEFT JOIN**: After a LEFT JOIN, `COUNT(*)` counts all rows including NULLed-out non-matches. `COUNT(o.order_id)` correctly counts only matched rows because it skips NULLs. This is an easy trap.

---

##   Practice Questions

1. Write a query to list all customers along with the total number of orders they have placed. Customers who have never ordered should show a count of 0.
```sql
SELECT
    c.customer_id,
    COUNT(o.order_id) AS order_count
FROM customer c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id;
```

3. Find all employees who are **not assigned** to any department (i.e., their `dept_id` is NULL or has no matching department). Use a LEFT JOIN approach.
```sql
using anti join

SELECT employee_id
FROM employees e
LEFT JOIN deparmtent d 
ON e.dept_id=d.dept_id
WHERE d.dept_id IS NULL;
```

5. List all products along with any orders placed for them. Include products that have never been ordered, and show `NULL` for the order columns in that case.
```sql
SELECT p.*, o.*
FROM products p
LEFT JOIN orders o
ON p.product_id = o.product_id;
 
```
6. Write two versions of a query: one that shows all customers with orders that have `status = 'Delivered'` using a `WHERE` clause, and one using an `ON` clause. Explain the difference in results.
```sql
SELECT c.customer_id
FROM customer c
LEFT JOIN order o
ON c.customer_id = o.customer_id
WHERE o.status = 'Deliverd';

ir

SELECT c.customer_id
FROM customer c
LEFT JOIN order o
ON c.customer_id = o.customer_id
    AND o.status = 'Delivered';
```

8. For each department, show the number of employees currently in it. Include departments that have zero employees. Order by employee count descending.
```sql
SELECT d.dept_id,
       COUNT(e.employee_id) AS employee_count
FROM department d
LEFT JOIN employee e
ON d.dept_id = e.dept_id
GROUP BY d.dept_id
ORDER BY employee_count DESC;

```
