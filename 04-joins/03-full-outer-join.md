# FULL OUTER JOIN — Return Everything from Both Sides

> **Interview Priority**: 🟡 Important

---

## What Is It?

A **FULL OUTER JOIN** (also called **FULL JOIN**) returns **all rows from both tables**. Where a row in the left table has no match in the right table, the right-side columns are `NULL`. Where a row in the right table has no match in the left table, the left-side columns are `NULL`. It is the union of LEFT JOIN and RIGHT JOIN behavior.

Think of it as: "Give me everything — matched rows joined together, plus orphaned rows from the left with NULLs on the right, plus orphaned rows from the right with NULLs on the left."

---

## Syntax

```sql
-- Standard FULL OUTER JOIN (PostgreSQL, SQL Server, Oracle, DB2)
SELECT columns
FROM   left_table  l
FULL OUTER JOIN right_table r
    ON l.key = r.key;

-- Shorthand (OUTER keyword is optional)
SELECT columns
FROM   left_table  l
FULL JOIN right_table r
    ON l.key = r.key;

-- MySQL / MariaDB workaround (no native FULL OUTER JOIN)
SELECT columns
FROM   left_table  l
LEFT JOIN right_table r
    ON l.key = r.key

UNION

SELECT columns
FROM   left_table  l
RIGHT JOIN right_table r
    ON l.key = r.key;
```

---

## Key Concepts

- **Both sides preserved**: Every row from both tables appears in the output — either with a match (joined together) or with NULLs filling the unmatched side.
- **MySQL has no native FULL OUTER JOIN**: MySQL and MariaDB do not support the `FULL OUTER JOIN` syntax. You must emulate it using `LEFT JOIN UNION RIGHT JOIN`. This is an extremely common interview question for MySQL-focused roles.
- **UNION automatically deduplicates**: In the MySQL workaround, `UNION` (not `UNION ALL`) removes the duplicate rows that result from matched rows appearing in both the LEFT and RIGHT JOIN results.
- **Detecting orphans on either side**: Use `WHERE l.key IS NULL OR r.key IS NULL` to find rows that exist in only one of the two tables.
- **Rare in production OLTP**: FULL OUTER JOIN is less common in transactional systems but is very useful in **data reconciliation**, **ETL pipelines**, **reporting**, and **comparing two datasets**.
- **Performance**: Can be expensive because the engine must read all rows from both tables. Ensure join keys are indexed.

---

## When to Use FULL OUTER JOIN

| Use Case | Description |
|---|---|
| **Data reconciliation** | Compare two tables (e.g., source vs target) and find rows present in only one |
| **Audit/diff reports** | Find employees in HR system but not in payroll system, and vice versa |
| **ETL validation** | Identify missing or extra records after a data load |
| **Symmetric reporting** | Report on all departments and all employees together, even orphaned ones |
| **Merging datasets** | Combine two independently sourced datasets with potential gaps on either side |

---

## Examples

### Example 1 — All Employees and All Departments (Including Orphaned Rows on Both Sides)

```sql
-- PostgreSQL / SQL Server / Oracle
SELECT
    e.emp_id,
    e.name          AS employee_name,
    e.salary,
    d.dept_id,
    d.dept_name,
    d.location
FROM employees e
FULL OUTER JOIN departments d
    ON e.dept_id = d.dept_id;
```

**Sample Output:**

```
emp_id | employee_name | salary   | dept_id | dept_name   | location
-------|---------------|----------|---------|-------------|----------
1      | Aman          | 85000.00 | 10      | Engineering | Bangalore
5      | Dev           | 78000.00 | 10      | Engineering | Bangalore
2      | Priya         | 62000.00 | 20      | HR          | Mumbai
3      | Ravi          | 91000.00 | 30      | Finance     | Delhi
4      | Zara          | 74000.00 | 40      | Marketing   | Bangalore
6      | Nisha         | 55000.00 | NULL    | NULL        | NULL      ← no dept
NULL   | NULL          | NULL     | 50      | Legal       | Hyderabad ← no employees
```

> Row for **Nisha**: She exists in `employees` with no matching department → right side is NULL.
> Row for **Legal**: It exists in `departments` with no employees → left side is NULL.

---

### Example 2 — MySQL Workaround Using UNION

```sql
-- MySQL / MariaDB: emulate FULL OUTER JOIN
SELECT
    e.emp_id,
    e.name          AS employee_name,
    d.dept_name,
    d.location
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id

UNION

SELECT
    e.emp_id,
    e.name          AS employee_name,
    d.dept_name,
    d.location
FROM employees e
RIGHT JOIN departments d
    ON e.dept_id = d.dept_id;
```

> The `UNION` (without `ALL`) deduplicates rows. Matched rows that appear in both the LEFT and RIGHT JOIN results are merged into one. Using `UNION ALL` here would cause matched rows to appear twice — a common mistake.

---

### Example 3 — Finding Orphaned Rows on BOTH Sides

```sql
-- Employees without a department AND departments without employees
SELECT
    e.emp_id,
    e.name          AS employee_name,
    d.dept_id,
    d.dept_name,
    CASE
        WHEN d.dept_id IS NULL THEN 'Employee has no department'
        WHEN e.emp_id  IS NULL THEN 'Department has no employees'
    END AS issue_description
FROM employees e
FULL OUTER JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.dept_id IS NULL      -- employee has no matching dept
   OR d.dept_id IS NULL;     -- dept has no matching employee (but wait — we need left-side IS NULL)
```

> **Correction for full accuracy** — filter should be:

```sql
WHERE e.emp_id IS NULL       -- dept row has no matching employee
   OR d.dept_id IS NULL;     -- employee row has no matching dept
```

**Sample Output:**

```
emp_id | employee_name | dept_id | dept_name | issue_description
-------|---------------|---------|-----------|-----------------------------
6      | Nisha         | NULL    | NULL      | Employee has no department
NULL   | NULL          | 50      | Legal     | Department has no employees
```

---

### Example 4 — Data Reconciliation: Orders Without a Product, Products Without Orders

```sql
-- Find products that were never ordered, and orders with missing product references
SELECT
    p.product_id,
    p.product_name,
    p.category,
    o.order_id,
    o.amount
FROM products p
FULL OUTER JOIN orders o
    ON p.product_id = o.product_id
WHERE p.product_id IS NULL
   OR o.product_id IS NULL;
```

**Sample Output:**

```
product_id | product_name       | category    | order_id | amount
-----------|--------------------|-------------|----------|--------
NULL       | NULL               | NULL        | 107      | 320.00   ← orphaned order
5          | Bluetooth Speaker  | Electronics | NULL     | NULL     ← never ordered
6          | Running Shoes      | Clothing    | NULL     | NULL     ← never ordered
```

---

### Example 5 — Comparing Employee Records Across Two Systems (Self-Referential Pattern)

A common real-world use: reconcile `employees` table (production) against a `performance` table (may have records for former employees no longer in the main table).

```sql
SELECT
    e.emp_id        AS emp_emp_id,
    e.name,
    p.emp_id        AS perf_emp_id,
    p.year,
    p.rating
FROM employees e
FULL OUTER JOIN performance p
    ON e.emp_id = p.emp_id
WHERE e.emp_id IS NULL      -- performance record exists, but employee doesn't (ex-employee)
   OR p.emp_id IS NULL;     -- employee exists, but no performance record yet
```

**Sample Output:**

```
emp_emp_id | name  | perf_emp_id | year | rating
-----------|-------|-------------|------|-------
NULL       | NULL  | 99          | 2022 | B      ← ex-employee still has perf record
7          | Kiran | NULL        | NULL | NULL   ← new employee, no perf record yet
```

---

## Database Support Summary

| Database   | Native FULL OUTER JOIN | Syntax |
|------------|------------------------|--------|
| PostgreSQL | ✅ Yes | `FULL OUTER JOIN` or `FULL JOIN` |
| SQL Server | ✅ Yes | `FULL OUTER JOIN` or `FULL JOIN` |
| Oracle     | ✅ Yes | `FULL OUTER JOIN` or `FULL JOIN` |
| DB2        | ✅ Yes | `FULL OUTER JOIN` |
| MySQL      | ❌ No  | Emulate with `LEFT JOIN UNION RIGHT JOIN` |
| MariaDB    | ❌ No  | Emulate with `LEFT JOIN UNION RIGHT JOIN` |
| SQLite     | ✅ Yes (v3.39+, 2022) | `FULL OUTER JOIN` |

---

## Interview Tips

1. **"Does MySQL support FULL OUTER JOIN?"** — No. This is a very commonly asked question. The workaround is `LEFT JOIN UNION RIGHT JOIN`. Make sure you can write it from memory.

2. **"What's the difference between FULL OUTER JOIN and CROSS JOIN?"** — FULL OUTER JOIN still has a join condition (`ON`) and only matches rows; unmatched rows get NULLs. CROSS JOIN has no condition and produces every possible combination (Cartesian product).

3. **"Why UNION and not UNION ALL in the MySQL workaround?"** — Because matched rows appear in both the LEFT JOIN and RIGHT JOIN result sets. `UNION ALL` would include them twice. `UNION` deduplicates.

4. **"When would you use FULL OUTER JOIN?"** — Data reconciliation, finding discrepancies between two datasets, ETL validation, auditing. Not typically used in day-to-day OLTP queries.

5. **Orphan detection pattern**: Be ready to write a query that finds rows present in one table but not the other using `FULL OUTER JOIN ... WHERE left.key IS NULL OR right.key IS NULL`.

---

## ❓ Practice Questions

1. Write a FULL OUTER JOIN query to list all employees and all departments together, including employees with no department and departments with no employees. Use any database that supports it natively.

2. Write the MySQL-compatible equivalent (using UNION of LEFT and RIGHT JOIN) for the query in Question 1.

3. Find all products that have never appeared in any order, AND all orders that reference a product not in the products table, using a FULL OUTER JOIN. Display the relevant IDs and names.

4. Write a query using FULL OUTER JOIN between `employees` and `performance` to identify: (a) employees with no performance records, and (b) performance records with no matching employee. Label each type of mismatch.

5. You are given two data sources: the `customers` table and the `orders` table. Use a FULL OUTER JOIN to find customers who have never ordered AND orders that have no associated customer. What does this tell you about data integrity?
