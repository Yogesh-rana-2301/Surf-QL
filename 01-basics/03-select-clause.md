# SELECT Clause — Retrieving Data from Tables

> **Interview Priority**: 🔴 Must Know

## What Is It?

`SELECT` is the most frequently used SQL statement. It retrieves rows and columns from one or more tables. You can select specific columns, all columns, computed expressions, or distinct values. Every data-retrieval query starts with `SELECT` — mastering its nuances separates good SQL writers from great ones.

## Syntax

```sql
-- Select specific columns
SELECT column1, column2, ... FROM table_name;

-- Select all columns (use only for exploration, not production)
SELECT * FROM table_name;

-- Select with a computed expression
SELECT column1, expression AS alias FROM table_name;

-- Select unique values only
SELECT DISTINCT column1 FROM table_name;
```

## Key Concepts

- **Column order is yours to define**: `SELECT name, salary` and `SELECT salary, name` return the same data in different column orders.
- **`AS` creates an alias**: Aliases rename a column or expression in the result set. The alias can be used in `ORDER BY` but NOT in `WHERE` (WHERE is evaluated before SELECT in the logical order).
- **`AS` keyword is optional**: `SELECT salary * 1.1 annual_raise` is valid but using `AS` is clearer and recommended.
- **`DISTINCT` applies to the entire row**: `SELECT DISTINCT dept_id, name` returns unique combinations of both columns, not just unique `dept_id` values.
- **`SELECT *` pitfalls**: Returns all columns — including ones added later by schema changes — which can break application code. It also prevents the query optimizer from using covering indexes, and sends unnecessary data over the network.
- **Expressions in SELECT**: You can use arithmetic operators (`+`, `-`, `*`, `/`), string functions (`CONCAT`, `UPPER`), date functions (`YEAR`, `DATEDIFF`), and conditional logic (`CASE WHEN`) directly in `SELECT`.

## Examples

```sql
-- 1. Select specific columns from employees
SELECT emp_id, name, salary
FROM employees;
-- Returns only 3 columns for all 12 rows
```

```sql
-- 2. Select all columns (fine for quick exploration)
SELECT *
FROM departments;
-- Returns dept_id, dept_name, location for all 4 departments
```

```sql
-- 3. Computed expression — salary after 10% raise
SELECT
    name,
    salary,
    salary * 1.10            AS new_salary,
    salary * 0.10            AS raise_amount
FROM employees;
-- new_salary and raise_amount appear as computed columns in the result
```

```sql
-- 4. String expression — full greeting using CONCAT
SELECT
    CONCAT('Hello, ', name, '!') AS greeting,
    email
FROM employees;
-- Output: "Hello, Arjun Mehta!", "arjun.mehta@company.com"
```

```sql
-- 5. DISTINCT — unique departments that have at least one employee
SELECT DISTINCT dept_id
FROM employees;
-- Returns: 10, 20, 30, 40, NULL (for unassigned employees)
```

```sql
-- 6. DISTINCT on multiple columns — unique city+category combinations
SELECT DISTINCT city
FROM customers;
-- Returns: Mumbai, Bengaluru, Delhi, Chennai, Pune
```

```sql
-- 7. Date expression — years since hire
SELECT
    name,
    hire_date,
    YEAR(CURDATE()) - YEAR(hire_date) AS years_at_company
FROM employees;
```

```sql
-- 8. Aliasing a table (useful in JOINs and subqueries)
SELECT e.name, e.salary
FROM employees AS e;
-- Table alias 'e' can replace 'employees' throughout the query
```

```sql
-- 9. CASE WHEN expression in SELECT (conditional column)
SELECT
    name,
    salary,
    CASE
        WHEN salary >= 90000 THEN 'Senior'
        WHEN salary >= 70000 THEN 'Mid-level'
        ELSE 'Junior'
    END AS seniority_band
FROM employees;
```

```sql
-- 10. Why SELECT * is bad — an example of what can go wrong
-- Imagine a table originally had 5 columns. You write:
SELECT * FROM employees;
-- A month later, someone adds a 'ssn' (social security number) column.
-- Now your app is accidentally returning sensitive data to the UI.
-- Had you written SELECT emp_id, name, salary, ... — no issue.
```

## Interview Tips

1. **Why is `SELECT *` bad in production?** Three reasons: (1) returns sensitive/unused columns, (2) breaks if schema changes (column order shifts), (3) prevents the optimizer from using covering indexes. Always name your columns explicitly in production code.

2. **Alias in WHERE clause**: Aliases defined in `SELECT` **cannot** be used in the `WHERE` clause because of SQL's logical processing order: `FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`. Aliases are only available from `ORDER BY` onward.

3. **`DISTINCT` vs `GROUP BY`**: Both can return unique values. `SELECT DISTINCT dept_id FROM employees` and `SELECT dept_id FROM employees GROUP BY dept_id` produce the same result. But `GROUP BY` allows aggregation (`COUNT`, `SUM`), while `DISTINCT` does not.

4. **`SELECT` without `FROM`**: Valid in MySQL and PostgreSQL. `SELECT 1+1;` returns `2`. Useful for testing expressions or checking server connectivity.

5. **Column aliasing with reserved words**: If your alias is a SQL keyword (like `order` or `from`), wrap it in backticks (MySQL) or double quotes (ANSI SQL): `` SELECT order_id AS `order` ``.

## ❓ Practice Questions

1. Write a query to display each employee's `name`, `salary`, and a computed column called `monthly_salary` (annual salary divided by 12) from the `employees` table.

2. Write a query to show all unique `category` values from the `products` table. How many distinct categories exist?

3. Write a `SELECT` statement that displays employee `name`, their `email` in uppercase (use `UPPER()`), and a label column called `domain` that shows only the domain part of the email (e.g., `company.com`). Use `SUBSTRING_INDEX(email, '@', -1)`.

4. Without using `WHERE`, write a query using `SELECT` and `CASE WHEN` to label each product from the `products` table as `'Expensive'` if price > 10000, `'Moderate'` if price between 1000 and 10000, and `'Affordable'` otherwise.

5. A teammate writes `SELECT DISTINCT dept_id, name FROM employees`. They expect to see only 4 unique `dept_id` values. Explain why they see more than 4 rows, and how `DISTINCT` actually works on multiple columns.
