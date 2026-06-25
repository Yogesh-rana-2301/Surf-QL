# CROSS JOIN & SELF JOIN — Cartesian Products and Recursive Relationships

> **Interview Priority**: 🟡 Important

---

## What Is It?

**CROSS JOIN** produces the **Cartesian product** of two tables: every row from the left table is combined with every row from the right table. If table A has `m` rows and table B has `n` rows, the result has `m × n` rows. There is no `ON` condition — all combinations are produced unconditionally.

**SELF JOIN** is when a table is joined **to itself**. It is not a separate join type — it uses INNER, LEFT, or any other join, but with the same table on both sides (distinguished by aliases). The classic use case is hierarchical data where a row references another row in the same table — like the `employees` table where `manager_id` references another employee's `emp_id`.

---

## Syntax

```sql
-- CROSS JOIN (explicit)
SELECT columns
FROM   table_a
CROSS JOIN table_b;

-- CROSS JOIN (implicit — produces same result, avoid in modern SQL)
SELECT columns
FROM   table_a, table_b;

-- SELF JOIN (using INNER JOIN syntax)
SELECT columns
FROM   employees e1
JOIN   employees e2
    ON e1.manager_id = e2.emp_id;

-- SELF JOIN (using LEFT JOIN to include employees with no manager)
SELECT columns
FROM   employees e
LEFT JOIN employees mgr
    ON e.manager_id = mgr.emp_id;
```

---

## Key Concepts — CROSS JOIN

- **No ON clause**: CROSS JOIN requires no join condition. Adding a `WHERE` to a CROSS JOIN filters the Cartesian product (which turns it into an equi-join equivalent — some optimizers may even rewrite it).
- **Row explosion**: With large tables, this is extremely expensive. A CROSS JOIN of 1,000-row and 1,000-row tables yields 1,000,000 rows. Always validate table sizes before cross-joining.
- **Legitimate use cases**:
  - Generating all combinations: pairing all products with all customers for hypothetical analysis
  - Building a calendar or number series by crossing a small numbers table
  - Test data generation
  - Finding all pairs that need comparison (e.g., all employee-employee pairs)
- **Accidental CROSS JOIN**: The most dangerous bug — forgetting the `ON` clause in an implicit join (`FROM a, b WHERE ...`) creates a Cartesian product if the WHERE has no join predicate.

---

## Key Concepts — SELF JOIN

- **Aliases are mandatory**: Both references to the table must have distinct aliases (e.g., `e` for employee, `mgr` for manager) so SQL can distinguish which column belongs to which "copy".
- **Hierarchical data**: The `employees` table uses `manager_id` as a self-referencing foreign key. A SELF JOIN on `employees.manager_id = employees.emp_id` lets you fetch both employee and their manager in one row.
- **NULL managers**: The CEO or top-level employees have no manager (`manager_id IS NULL`). Use `LEFT JOIN` (not INNER JOIN) in a self-join if you want to include employees with no manager.
- **Multiple levels**: A single SELF JOIN gives you one level (employee + their direct manager). For deeper hierarchy (grandparent, great-grandparent), you need recursive CTEs in most databases.
- **Not limited to hierarchy**: SELF JOINs are also used for **finding duplicates**, **comparing rows within the same table**, or **detecting adjacent records**.

---

## Examples — CROSS JOIN

### Example 1 — All Customer × Product Combinations (Potential Recommendations)

```sql
-- Generate every (customer, product) pair — useful for recommendation-system seeding
SELECT
    c.customer_id,
    c.name          AS customer_name,
    p.product_id,
    p.product_name,
    p.category,
    p.price
FROM customers c
CROSS JOIN products p
ORDER BY c.customer_id, p.product_id;
```

**Sample Output (excerpt):**

```
customer_id | customer_name | product_id | product_name        | category    | price
------------|---------------|------------|---------------------|-------------|--------
1           | Arjun Mehta   | 1          | Wireless Mouse      | Electronics | 799.00
1           | Arjun Mehta   | 2          | Cotton T-Shirt      | Clothing    | 499.00
1           | Arjun Mehta   | 3          | Instant Noodles     | Food        | 45.00
...         | ...           | ...        | ...                 | ...         | ...
2           | Sneha Patel   | 1          | Wireless Mouse      | Electronics | 799.00
2           | Sneha Patel   | 2          | Cotton T-Shirt      | Clothing    | 499.00
...
```

> With 5 customers and 6 products, this produces 30 rows. Every combination is represented exactly once.

---

### Example 2 — Cross Join to Find Products Not Yet Ordered by a Customer

```sql
-- All (customer, product) pairs that have NO order — potential marketing targets
SELECT
    c.customer_id,
    c.name          AS customer_name,
    p.product_id,
    p.product_name
FROM customers c
CROSS JOIN products p
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.product_id  = p.product_id
)
ORDER BY c.customer_id, p.product_id;
```

> Generate all possible (customer, product) pairs via CROSS JOIN, then subtract the ones where an order already exists. The result is the set of products a customer has never ordered — prime candidates for targeted promotions.

---

### Example 3 — Generating a Series Using CROSS JOIN (Number Table Trick)

```sql
-- Cross join a small digit table to generate numbers 1–100
-- Useful for generating test data or date sequences
SELECT
    (tens.n * 10 + ones.n) AS num
FROM
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) AS tens
CROSS JOIN
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) AS ones
ORDER BY num;
```

> Produces integers 0–99. Add 1 in the outer select if you want 1–100. This technique is used to generate date ranges or synthetic rows for calendar tables.

---

### Example 4 — Detecting Accidental CROSS JOIN (What to Watch For)

```sql
-- ❌ BUG: Implicit join missing the WHERE join predicate
SELECT e.name, d.dept_name
FROM   employees e, departments d;
-- Result: 6 employees × 4 departments = 24 rows — almost certainly wrong!

-- ✅ Correct: Explicit join condition
SELECT e.name, d.dept_name
FROM   employees e
JOIN   departments d ON e.dept_id = d.dept_id;
```

---

## Examples — SELF JOIN

### Example 5 — Employee and Their Direct Manager

```sql
-- Each employee paired with their manager's name
SELECT
    e.emp_id,
    e.name          AS employee_name,
    e.salary,
    mgr.emp_id      AS manager_id,
    mgr.name        AS manager_name
FROM employees e
INNER JOIN employees mgr       -- same table, different alias
    ON e.manager_id = mgr.emp_id;
```

**Sample Output:**

```
emp_id | employee_name | salary   | manager_id | manager_name
-------|---------------|----------|------------|-------------
1      | Aman          | 85000.00 | 3          | Ravi
2      | Priya         | 62000.00 | 3          | Ravi
4      | Zara          | 74000.00 | 3          | Ravi
5      | Dev           | 78000.00 | 1          | Aman
```

> Employees whose `manager_id` is NULL (like Ravi, the top-level manager) are excluded by INNER JOIN. Use LEFT JOIN to include them.

---

### Example 6 — Including Top-Level Employees (No Manager) with LEFT JOIN

```sql
SELECT
    e.emp_id,
    e.name              AS employee_name,
    e.salary,
    COALESCE(mgr.name, '-- No Manager (CEO/Head) --') AS manager_name
FROM employees e
LEFT JOIN employees mgr
    ON e.manager_id = mgr.emp_id;
```

**Sample Output:**

```
emp_id | employee_name | salary   | manager_name
-------|---------------|----------|-------------------------------
1      | Aman          | 85000.00 | Ravi
2      | Priya         | 62000.00 | Ravi
3      | Ravi          | 91000.00 | -- No Manager (CEO/Head) --
4      | Zara          | 74000.00 | Ravi
5      | Dev           | 78000.00 | Aman
6      | Nisha         | 55000.00 | -- No Manager (CEO/Head) --
```

> Ravi and Nisha have `manager_id = NULL`. LEFT JOIN retains them; `COALESCE` provides a readable label instead of NULL.

---

### Example 7 — Find Employees Who Earn More Than Their Manager

```sql
SELECT
    e.name          AS employee_name,
    e.salary        AS employee_salary,
    mgr.name        AS manager_name,
    mgr.salary      AS manager_salary
FROM employees e
INNER JOIN employees mgr
    ON e.manager_id = mgr.emp_id
WHERE e.salary > mgr.salary;
```

**Sample Output:**

```
employee_name | employee_salary | manager_name | manager_salary
--------------|-----------------|--------------|---------------
Aman          | 85000.00        | Ravi         | 91000.00
```

> Wait — Aman doesn't earn more than Ravi (91K > 85K). In a dataset where Dev (78K) reports to Aman (85K), the result would be empty. This query pattern is a very common interview exercise.

---

### Example 8 — Finding Duplicate Emails in Employees (SELF JOIN for De-duplication)

```sql
-- Detect employees sharing the same email (data quality check)
SELECT
    e1.emp_id,
    e1.name,
    e1.email,
    e2.emp_id   AS duplicate_emp_id,
    e2.name     AS duplicate_name
FROM employees e1
JOIN employees e2
    ON  e1.email  = e2.email
    AND e1.emp_id < e2.emp_id;  -- < avoids (A,B) and (B,A) — only lists each pair once
```

> The `e1.emp_id < e2.emp_id` trick is the standard way to avoid self-matching (`A,A`) and duplicate pairs (`A,B` and `B,A`). Change `<` to `<>` to also include `(B,A)` — but usually `<` is what you want.

---

## Interview Tips

1. **"What is a CROSS JOIN and when would you use it?"** — Cartesian product, no join condition. Use cases: all combinations (customer × product for recommendations), generating number series, or test data. Interviewers listen for you to mention the row explosion risk.

2. **"How do you implement a hierarchy query?"** — SELF JOIN for one level of hierarchy. For unlimited depth, use a **recursive CTE** (`WITH RECURSIVE`). Know both and when to use each.

3. **"Why do we need two aliases in a SELF JOIN?"** — Because SQL needs to distinguish which copy of the table each column reference belongs to. Without aliases, you'd have ambiguous column names.

4. **"What happens if you forget the `ON` clause in a JOIN?"** — In explicit join syntax, it's a syntax error. In implicit syntax (`FROM a, b`), you get an accidental CROSS JOIN — one of the most destructive bugs in SQL.

5. **"How do you list each pair only once in a SELF JOIN?"** — Use `AND e1.emp_id < e2.emp_id` in the join condition. This eliminates both self-matches (A=A) and reversed duplicates (B,A when A,B already exists).

---

## ❓ Practice Questions

1. Write a CROSS JOIN query to generate all possible (employee, department) pairs — regardless of which department the employee actually belongs to. How many rows do you expect if there are 6 employees and 4 departments?

2. Using a SELF JOIN on the `employees` table, write a query to display each employee's name, their direct manager's name, and their department. Exclude employees who report to no one.

3. Write a SELF JOIN query to find all pairs of employees (from the same department) where one earns at least 10,000 more than the other. Display both names, both salaries, and the department name.

4. Use a CROSS JOIN between `products` and `customers` combined with a `NOT EXISTS` subquery to find all (customer, product) combinations where the customer has **never ordered** that product.

5. Write a query using a SELF JOIN to identify which employees are managers (i.e., appear as `manager_id` in at least one other employee's row). Display manager name, their own manager's name, and how many direct reports they have.
