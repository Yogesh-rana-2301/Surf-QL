# INNER JOIN — Return Only the Matching Rows

> **Interview Priority**: 🔴 Must Know

---

## What Is It?

An **INNER JOIN** combines rows from two (or more) tables where the join condition is satisfied. If a row in either table has **no matching row** in the other table, it is **excluded entirely** from the result. The output is the logical **intersection** of both tables based on the join key.

INNER JOIN is the **default join type** — writing `JOIN` without a qualifier is equivalent to `INNER JOIN`. Most SQL engines treat them identically.

---

## Syntax

```sql
-- Basic INNER JOIN
SELECT columns
FROM   table_a
INNER JOIN table_b
    ON table_a.key = table_b.key;

-- Shorthand (INNER is optional)
SELECT columns
FROM   table_a
JOIN   table_b
    ON table_a.key = table_b.key;

-- Multi-condition join
SELECT columns
FROM   table_a
JOIN   table_b
    ON  table_a.key1 = table_b.key1
    AND table_a.key2 = table_b.key2;

-- Old-style implicit join (avoid in new code)
SELECT columns
FROM   table_a, table_b
WHERE  table_a.key = table_b.key;
```

---

## Key Concepts

- **Exclusion of non-matches**: Any employee whose `dept_id` doesn't exist in `departments` (e.g., `dept_id = NULL`) will **not appear** in the result. This is the defining behavior of INNER JOIN.
- **Default join type**: `JOIN` and `INNER JOIN` are synonymous in all major SQL databases (MySQL, PostgreSQL, SQL Server, Oracle, SQLite).
- **Equi-join**: The most common form of INNER JOIN where the condition uses `=`. It links a foreign key in one table to a primary key in another.
- **Non-equi join**: An INNER JOIN where the condition uses `<`, `>`, `BETWEEN`, `!=`, etc. (see `06-advanced-join-patterns.md`).
- **Multi-condition joins**: Use `AND` in the `ON` clause to match on multiple columns — common when dealing with composite keys or additional filters that are part of the relationship definition.
- **Column aliasing**: When both tables share a column name (like both having `name`), always qualify with the table alias to avoid ambiguity errors.
- **Order of tables**: For INNER JOIN, the order of tables doesn't affect the result set (it is commutative), though it can affect the query plan.
- **Result size**: The result can have **at most** `min(rows_in_A, rows_in_B)` rows if the join key is unique on both sides. With one-to-many relationships, rows from the "one" side can multiply.

---

## Examples

### Example 1 — Employees with Their Department Names

```sql
SELECT
    e.emp_id,
    e.name        AS employee_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
INNER JOIN departments d
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
```

> **Note**: Any employee with `dept_id = NULL` or a `dept_id` that has no matching row in `departments` will be **silently dropped** from this result. This is why it matters to know which join type to use.

---

### Example 2 — Orders with Customer Details

```sql
SELECT
    o.order_id,
    c.name          AS customer_name,
    c.city,
    o.amount,
    o.order_date,
    o.status
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id;
```

**Sample Output:**

```
order_id | customer_name | city      | amount   | order_date | status
---------|---------------|-----------|----------|------------|----------
101      | Arjun Mehta   | Mumbai    | 2500.00  | 2024-01-15 | Delivered
102      | Sneha Patel   | Bangalore | 1800.00  | 2024-02-03 | Shipped
103      | Arjun Mehta   | Mumbai    | 4200.00  | 2024-03-10 | Delivered
104      | Kavya Nair    | Chennai   | 950.00   | 2024-03-22 | Pending
```

> **Note**: Customers who have never placed an order are excluded. Orders without a matching customer (orphaned foreign key) are also excluded.

---

### Example 3 — Orders with Customer AND Product Details (3-Table Join)

```sql
SELECT
    o.order_id,
    c.name          AS customer_name,
    p.product_name,
    p.category,
    o.amount,
    o.status
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
INNER JOIN products p
    ON o.product_id = p.product_id;
```

**Sample Output:**

```
order_id | customer_name | product_name   | category    | amount  | status
---------|---------------|----------------|-------------|---------|----------
101      | Arjun Mehta   | Wireless Mouse | Electronics | 2500.00 | Delivered
102      | Sneha Patel   | Cotton T-Shirt | Clothing    | 1800.00 | Shipped
103      | Arjun Mehta   | Noise Cancelling Headphones | Electronics | 4200.00 | Delivered
```

---

### Example 4 — Equi-Join with Additional Filter (not part of the relationship)

```sql
-- Employees in Engineering or Finance with salary > 80000
SELECT
    e.name,
    e.salary,
    d.dept_name
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id
WHERE d.dept_name IN ('Engineering', 'Finance')
  AND e.salary > 80000;
```

**Sample Output:**

```
name  | salary   | dept_name
------|----------|----------
Aman  | 85000.00 | Engineering
Ravi  | 91000.00 | Finance
```

> **Important**: The `WHERE` clause filters rows **after** the join. The `ON` clause defines the relationship. Keep them separate and intentional.

---

### Example 5 — Multi-Condition Join (Composite Key)

```sql
-- Join performance records with employees, matching BOTH emp_id AND a specific year
-- Useful when rows in performance are keyed by (emp_id, year)
SELECT
    e.name,
    p.year,
    p.rating,
    p.bonus
FROM employees e
INNER JOIN performance p
    ON  e.emp_id = p.emp_id
    AND p.year = 2023;
```

**Sample Output:**

```
name  | year | rating | bonus
------|------|--------|--------
Aman  | 2023 | A      | 12000
Priya | 2023 | B      | 7000
Ravi  | 2023 | A      | 15000
Dev   | 2023 | C      | 3000
```

> **Note**: Filtering in the `ON` clause vs the `WHERE` clause produces **identical results for INNER JOIN** but **different results for OUTER JOINs**. This distinction is a classic interview trap — see `02-left-right-join.md`.

---

### Example 6 — Old-Style Implicit Join (Recognize, but Don't Write)

```sql
-- You may see this in legacy SQL code — avoid writing it yourself
SELECT e.name, d.dept_name
FROM   employees e, departments d
WHERE  e.dept_id = d.dept_id;
```

This is functionally equivalent to an `INNER JOIN ... ON` but is harder to read, error-prone (forgetting the `WHERE` causes a CROSS JOIN), and not supported with `LEFT JOIN` semantics.

---

## Interview Tips

1. **"What happens to unmatched rows in an INNER JOIN?"** — They are excluded entirely. Neither side's unmatched rows appear in the result. This is the most common follow-up question.

2. **"What is the difference between `JOIN` and `INNER JOIN`?"** — They are identical. `INNER JOIN` is just the explicit form. Knowing this shows you understand SQL grammar.

3. **"`ON` vs `WHERE` for filtering"** — For INNER JOIN, both produce the same result. But mention that for OUTER JOINs they behave differently (you'll look sharp for volunteering this).

4. **"What is an equi-join?"** — An INNER JOIN where the condition uses `=` to match a foreign key to a primary key. Almost all joins in practice are equi-joins.

5. **"What is the result size of a JOIN?"** — It depends on the relationship. One-to-one: same count as either table. One-to-many: the "one" side's rows multiply. Many-to-many (without a bridge table): Cartesian-like explosion. Always reason about cardinality when asked about query performance.

6. **"Why is INNER JOIN the default?"** — Historically, it maps directly to the relational algebra operation of a natural join and is the most intuitive: combine what exists in both. It also tends to have good query optimizer support.

---

## ❓ Practice Questions

1. Write a query to display each employee's name, their department name, and department location. Exclude employees who are not assigned to any department.
```sql
SELECT e.name,d.dept_name,d.dept_location
FROM employyes e
INNER JOIN department d
ON e.dept_id = d.dept_id

```

3. List all orders (order_id, amount, status) along with the customer's name and city. Only include orders where the customer is from `'Mumbai'` or `'Bangalore'`.
```sql
SELECT
    c.name,
    c.city,
    o.order_id,
    o.amount,
    o.status
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
WHERE c.city IN ('Mumbai', 'Bangalore');
```

5. Find all employees who received a performance rating of `'A'` in the year 2023. Display the employee name, department name, rating, and bonus amount.
```sql
SELECT
    e.name,
    d.dept_name,
    p.rating,
    p.bonus
FROM employees e
INNER JOIN department d
ON e.dept_id = d.dept_id
INNER JOIN performance p
ON e.emp_id = p.emp_id
WHERE p.rating = 'A'
  AND p.year = 2023;

```

7. Write a query to show each order's details (order_id, order_date, amount) along with the product name, category, and customer name. Filter for only `'Delivered'` orders.
```sql
SELECT
    o.order_id,
    o.order_date,
    o.amount,
    p.product_name,
    p.category,
    c.name AS customer_name
FROM orders o
INNER JOIN customers c
ON o.customer_id = c.customer_id
INNER JOIN products p
ON o.product_id = p.product_id
WHERE o.status = 'Delivered';

```

9. How many orders has each customer placed? Display the customer name and order count. Only include customers who have placed at least one order. Order by order count descending.
```sql
SELECT c.name, COUNT (o.order_id) AS order_cnt
FROM customer c
INNER JOIN order o
ON c.customer_id=o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(o.order_id)>=1
ORDER BY order_cnt DESC; 

```
