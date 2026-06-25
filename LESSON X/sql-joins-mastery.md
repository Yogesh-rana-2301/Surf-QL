# SQL Joins Mastery Guide (Interview + Placement Focus)

This file is a complete guide to SQL joins for interview preparation.
It covers all major join types, when to use them, and common mistakes.

## 1) Why Joins Matter

Most real datasets are split across multiple tables.
Joins let you combine related data using keys.

Example relationships:

- employees.dept_id -> departments.dept_id
- orders.customer_id -> customers.customer_id

## 2) Sample Tables Used in Examples

```sql
-- employees
-- emp_id | name  | dept_id | manager_id | salary

-- departments
-- dept_id | dept_name

-- customers
-- customer_id | customer_name

-- orders
-- order_id | customer_id | order_date | amount
```

## 3) INNER JOIN

Use when:

- You only want matching rows from both tables.

Core idea:

- Return intersection of table A and table B based on join condition.

```sql
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
INNER JOIN departments d
  ON e.dept_id = d.dept_id;
```

Interview tip:

- Default join in many problems is INNER JOIN unless unmatched rows are needed.

## 4) LEFT JOIN (LEFT OUTER JOIN)

Use when:

- You want all rows from left table, plus matches from right table.

Core idea:

- Keep all left rows.
- Missing right values become NULL.

```sql
SELECT c.customer_id, c.customer_name, o.order_id
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id;
```

Common use-cases:

- Customers with and without orders.
- Parent records with optional child records.

## 5) RIGHT JOIN (RIGHT OUTER JOIN)

Use when:

- You want all rows from right table, plus matches from left table.

```sql
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d
  ON e.dept_id = d.dept_id;
```

Note:

- Same result can usually be written as LEFT JOIN by swapping table order.

## 6) FULL OUTER JOIN

Use when:

- You want all rows from both tables.
- Matched rows are combined.
- Non-matching rows appear with NULLs on missing side.

```sql
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d
  ON e.dept_id = d.dept_id;
```

Important dialect note:

- MySQL does not support FULL OUTER JOIN directly.
- Workaround uses UNION of LEFT JOIN and RIGHT JOIN.

MySQL-style workaround:

```sql
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.dept_id
UNION
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d
  ON e.dept_id = d.dept_id;
```

## 7) CROSS JOIN

Use when:

- You need Cartesian product (all combinations).

Core idea:

- Every row in A pairs with every row in B.

```sql
SELECT s.size, c.color
FROM sizes s
CROSS JOIN colors c;
```

Use-cases:

- Generating combinations.
- Matrix or calendar scaffolding.

Warning:

- Result size can explode quickly.

## 8) SELF JOIN

Use when:

- A table relates to itself.

Common case:

- Employee to manager mapping.

```sql
SELECT
  e.emp_id,
  e.name AS employee_name,
  m.emp_id AS manager_id,
  m.name AS manager_name
FROM employees e
LEFT JOIN employees m
  ON e.manager_id = m.emp_id;
```

## 9) NATURAL JOIN (Use Carefully)

Use when:

- You explicitly want automatic join on columns with same names.

```sql
SELECT *
FROM employees
NATURAL JOIN departments;
```

Why risky in interviews/production:

- Join behavior changes if schema changes.
- Hidden join columns reduce clarity.

Best practice:

- Prefer explicit JOIN ... ON.

## 10) EQUI JOIN and NON-EQUI JOIN

### EQUI JOIN

Join condition uses equality.

```sql
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d
  ON e.dept_id = d.dept_id;
```

### NON-EQUI (THETA) JOIN

Join condition uses <, >, BETWEEN, etc.

```sql
SELECT e.name, e.salary, b.band_name
FROM employees e
JOIN salary_bands b
  ON e.salary BETWEEN b.min_salary AND b.max_salary;
```

Interview relevance:

- Used in range mapping problems.

## 11) SEMI JOIN Pattern (EXISTS or IN)

Use when:

- You only need rows from left table that have a match in right table.
- You do not need columns from right table.

```sql
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.customer_id = c.customer_id
);
```

Equivalent style with IN:

```sql
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE c.customer_id IN (
  SELECT o.customer_id
  FROM orders o
);
```

## 12) ANTI JOIN Pattern (NOT EXISTS or LEFT JOIN IS NULL)

Use when:

- You need left-table rows with no matching right-table row.

### Preferred in interviews: NOT EXISTS

```sql
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE NOT EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.customer_id = c.customer_id
);
```

### Alternative: LEFT JOIN + IS NULL

```sql
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;
```

## 13) LATERAL JOIN / APPLY (Advanced)

Use when:

- Subquery needs columns from each row of the left table.
- Top-1 child per parent type problems.

PostgreSQL style:

```sql
SELECT c.customer_id, x.order_id, x.amount
FROM customers c
LEFT JOIN LATERAL (
  SELECT o.order_id, o.amount
  FROM orders o
  WHERE o.customer_id = c.customer_id
  ORDER BY o.order_date DESC
  LIMIT 1
) x ON TRUE;
```

SQL Server equivalent uses OUTER APPLY/CROSS APPLY.

## 14) ON vs WHERE in Outer Joins (Very Important)

For LEFT JOIN:

- Condition in ON keeps unmatched left rows.
- Condition in WHERE can remove NULL-matched rows and act like INNER JOIN.

### Condition in ON (keeps left rows)

```sql
SELECT c.customer_id, o.order_id
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
 AND o.amount > 1000;
```

### Condition in WHERE (may drop unmatched left rows)

```sql
SELECT c.customer_id, o.order_id
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
WHERE o.amount > 1000;
```

Interview question favorite:

- Why do these two queries return different counts?

## 15) Duplicate Explosion in Joins

Problem:

- One-to-many joins multiply rows.

Example:

- 1 customer with 5 orders becomes 5 rows after join.

How to control:

- Use GROUP BY for summaries.
- Use DISTINCT when logically correct.
- Use ROW_NUMBER to keep one row.

## 16) Join Order and Performance

Checklist:

- Index foreign keys and join keys.
- Filter early where possible.
- Avoid joining huge tables before reducing rows.
- Validate plan with EXPLAIN / EXPLAIN ANALYZE.
- Select only needed columns.

Useful indexes:

```sql
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_employees_dept_id ON employees(dept_id);
```

## 17) Null Handling in Joins

Key points:

- NULL does not equal NULL in standard equality joins.
- Outer joins introduce NULLs for unmatched side.
- Use COALESCE when needed for reporting output.

```sql
SELECT c.customer_name, COALESCE(o.order_id, 0) AS order_id
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id;
```

## 18) Multi-Table Join Pattern

Use when:

- Need data from 3 or more related tables.

```sql
SELECT
  o.order_id,
  c.customer_name,
  p.product_name,
  oi.quantity
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;
```

Best practice:

- Keep aliases clear.
- Add one join at a time while debugging.

## 19) Interview Quick Questions on Joins

Practice these:

1. Difference between INNER JOIN and LEFT JOIN.
2. Find customers with no orders.
3. Get employee and manager name from same table.
4. Top 1 latest order per customer.
5. Why moving a condition from ON to WHERE changes result.
6. Simulate FULL OUTER JOIN in MySQL.
7. Find departments with zero employees.

## 20) Join Selection Cheat Sheet

- Need only matching rows: INNER JOIN
- Need all left rows: LEFT JOIN
- Need all right rows: RIGHT JOIN
- Need all rows from both sides: FULL OUTER JOIN
- Need all combinations: CROSS JOIN
- Same table relation: SELF JOIN
- Existence check only: EXISTS (SEMI JOIN pattern)
- Non-existence check: NOT EXISTS (ANTI JOIN pattern)

## 21) Final Mastery Strategy

1. First master INNER and LEFT JOIN.
2. Then master ANTI JOIN and SELF JOIN.
3. Practice ON vs WHERE differences.
4. Solve top interview patterns repeatedly.
5. Explain join choice out loud while solving.

If you can choose the right join quickly and explain why, you are interview-ready.
