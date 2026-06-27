# GROUP BY — Aggregating Rows into Groups

> **Interview Priority**: 🔴 Must Know

## What Is It?

`GROUP BY` collapses multiple rows that share the same value(s) in the specified column(s) into a single summary row. It is almost always used with aggregate functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) to compute per-group statistics — like total salary per department or number of orders per customer.

## Syntax

```sql
SELECT   column1, column2, aggregate_function(column3)
FROM     table_name
[WHERE   condition]
GROUP BY column1, column2
[HAVING  group_condition]
[ORDER BY column1];
```

## Key Concepts

### SQL Execution Order (Critical)

```
1. FROM      — identify the table(s)
2. JOIN      — combine tables
3. WHERE     — filter individual rows
4. GROUP BY  — group filtered rows
5. HAVING    — filter groups
6. SELECT    — compute output columns
7. DISTINCT  — remove duplicates
8. ORDER BY  — sort final results
9. LIMIT     — cut the result set
```

This order explains two vital rules:
- **Aliases defined in `SELECT` cannot be used in `GROUP BY`** — `GROUP BY` executes before `SELECT`, so the alias doesn't exist yet (standard SQL). PostgreSQL is an exception and allows it.
- **`WHERE` cannot use aggregate functions** — aggregation hasn't happened yet at the `WHERE` stage. Use `HAVING` for that.

### GROUP BY Rules

- Every column in `SELECT` that is **not** inside an aggregate function **must** appear in `GROUP BY` (in standard SQL and MySQL strict mode). Violating this gives a `non-aggregated column` error.
- You can group by **multiple columns** — each unique combination of those columns forms one group.
- You can group by **expressions** (e.g., `YEAR(hire_date)`, `dept_id * 10`), not just raw column names.
- `NULL` values are grouped together — all rows with `NULL` in the grouping column form one group.


> there is a problem with grouping sets, cube, in mysql but not in oracle, and postgre, that it wont fill the not known values with NULL automatically so invalid, so think of grouping sets as
> ROLLUPs do work tho

```sql
SELECT
    Region,
    NULL AS Product,
    SUM(Amount)
FROM Sales
GROUP BY Region

UNION ALL

SELECT
    NULL AS Region,
    Product,
    SUM(Amount)
FROM Sales
GROUP BY Product;
```
### GROUPING SETS, ROLLUP, CUBE (Advanced)

These extensions generate multiple groupings in a single query, useful for reporting totals and subtotals without `UNION ALL`.

| Extension | What it generates |
|---|---|
| `GROUPING SETS ((a),(b),())` | One result per listed grouping |
| `ROLLUP (a, b)` | (a,b), (a), () — hierarchical subtotals |
| `CUBE (a, b)` | All 4 combinations: (a,b), (a), (b), () |

## Examples

### 1 — Count employees per department

```sql
SELECT dept_id, COUNT(*) AS employee_count
FROM employees
GROUP BY dept_id;

-- Result:
-- dept_id | employee_count
-- --------+---------------
-- 10      | 2   (Aman, Dev)
-- 20      | 1   (Priya)
-- 30      | 1   (Ravi)
-- 40      | 1   (Zara)
```

### 2 — Total and average salary per department

```sql
SELECT dept_id,
       SUM(salary)          AS total_salary,
       ROUND(AVG(salary), 2) AS avg_salary,
       MAX(salary)          AS highest_salary,
       MIN(salary)          AS lowest_salary
FROM employees
GROUP BY dept_id;
```

### 3 — Grouping by multiple columns (department + year hired)

```sql
SELECT dept_id,
       YEAR(hire_date) AS hire_year,
       COUNT(*)        AS hires
FROM employees
GROUP BY dept_id, YEAR(hire_date)
ORDER BY dept_id, hire_year;
```

### 4 — Why aliases don't work in GROUP BY (standard SQL)

```sql
-- ❌ This fails in standard SQL (and MySQL strict mode):
SELECT dept_id, YEAR(hire_date) AS yr, COUNT(*) AS cnt
FROM employees
GROUP BY dept_id, yr;   -- 'yr' alias not yet defined at GROUP BY stage

-- ✅ Correct — use the expression itself:
SELECT dept_id, YEAR(hire_date) AS yr, COUNT(*) AS cnt
FROM employees
GROUP BY dept_id, YEAR(hire_date);

-- ✅ PostgreSQL exception — allows alias in GROUP BY:
-- GROUP BY dept_id, yr;   -- works only in PostgreSQL
```

### 5 — Grouping by expression (salary tier)

```sql
SELECT
    CASE
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 75000 THEN 'Medium'
        ELSE                      'Low'
    END AS tier,
    COUNT(*) AS headcount,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY
    CASE
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 75000 THEN 'Medium'
        ELSE                      'Low'
    END;
```

### 6 — Orders per customer per status

```sql
SELECT customer_id, status, COUNT(*) AS order_count, SUM(amount) AS total_amount
FROM orders
GROUP BY customer_id, status
ORDER BY customer_id, status;
```

### 7 — ROLLUP: department totals + grand total

```sql
SELECT dept_id, SUM(salary) AS total_salary
FROM employees
GROUP BY ROLLUP(dept_id);

-- Result (PostgreSQL/MySQL 8+/SQL Server):
-- dept_id | total_salary
-- --------+-------------
-- 10      | 163000       ← Engineering subtotal
-- 20      | 62000        ← HR subtotal
-- 30      | 91000        ← Finance subtotal
-- 40      | 74000        ← Marketing subtotal
-- NULL    | 390000       ← Grand total (the ROLLUP row)
```

### 8 — GROUPING SETS: specific groupings

```sql
SELECT dept_id, YEAR(hire_date) AS hire_year, SUM(salary) AS total_salary
FROM employees
GROUP BY GROUPING SETS (
    (dept_id, YEAR(hire_date)),  -- per dept per year
    (dept_id),                   -- per dept total
    ()                           -- grand total
);
```

### 9 — CUBE: all combinations

```sql
SELECT dept_id, YEAR(hire_date) AS hire_year, SUM(salary)
FROM employees
GROUP BY CUBE(dept_id, YEAR(hire_date));
-- Generates subtotals for: (dept+year), (dept only), (year only), (grand total)
```

### 10 — Performance ratings per employee-year

```sql
SELECT emp_id, year, COUNT(*) AS reviews, AVG(bonus) AS avg_bonus
FROM performance
GROUP BY emp_id, year
ORDER BY emp_id, year;
```

## Interview Tips

1. **"Why can't you use a SELECT alias in GROUP BY?"** — Because of SQL's logical execution order: `GROUP BY` runs *before* `SELECT`, so aliases aren't resolved yet. PostgreSQL is lenient and allows it, but standard SQL does not. Always know this.
2. **"What happens to NULLs in GROUP BY?"** — `NULL` values are grouped together into a single group. Two rows with `NULL` in the grouping column are treated as belonging to the same group (unlike `NULL = NULL` in WHERE, which is unknown).
3. **Non-aggregated columns in SELECT** — In MySQL with `ONLY_FULL_GROUP_BY` mode disabled, you can select columns not in `GROUP BY` (MySQL picks a random row's value). This is a source of bugs — always include all non-aggregated columns in `GROUP BY`.
4. **ROLLUP vs CUBE** — `ROLLUP` creates hierarchical subtotals (left-to-right rollup). `CUBE` creates *all* combinations of subtotals. For a two-column group, `CUBE` gives 4 grouping sets vs `ROLLUP`'s 3.
5. **GROUP BY vs DISTINCT** — Both can produce unique combinations of column values. But `GROUP BY` is designed for aggregation; use `DISTINCT` when you just want unique rows without aggregation. Performance-wise they're often equivalent, but semantically different.

## Practice Questions

1. Write a query to find the **total salary** and **number of employees** in each department. Sort the result by total salary descending.

```sql
SELECT
       dept,
       SUM (salary) AS TOTAL,
       COUNT (*) AS numberOFEmployees

FROM employees
GROUP BY dept
ORDER BY TOTAL DESC;
```

3. Find the **average order amount** per `customer_id` from the `orders` table. Only include customers who have placed **more than 2 orders** (hint: you'll need `HAVING`)
```sql
SELECT
       customer_id,
       AVG(amount) AS average_order_amount
FROM orders
GROUP BY customer_id
HAVING COUNT(*)>2;

```

5. Write a query that groups `performance` records by `year` and `rating`, and shows the **count** and **average bonus** for each combination. Sort by year and then rating.
```sql
SELECT
    year,
    rating,
    COUNT(*) AS record_count,
    AVG(bonus) AS avg_bonus
FROM performance
GROUP BY year, rating
ORDER BY year, rating;
```


7. Using `ROLLUP`, write a query on the `orders` table that shows `SUM(amount)` grouped by `customer_id` with a grand total row included.
```sql
SELECT
       customer_id,
       SUM (amount)
FROM orders
GROUP BY ROLLUP (customer_id);

```

9. You want to count how many products exist in each `category` from the `products` table, and also count how many products fall into a **price band** (`CASE`: 'Budget' < 500, 'Mid' 500–2000, 'Premium' > 2000). Use two separate `GROUP BY` queries or combine them with `GROUPING SETS`.

```sql
SELECT
    category,
    COUNT(*) AS product_count
FROM products
GROUP BY category;





SELECT
    CASE
        WHEN price < 500 THEN 'Budget'
        WHEN price <= 2000 THEN 'Mid'
        ELSE 'Premium'
    END AS price_band,
    COUNT(*) AS product_count
FROM products
GROUP BY
    CASE
        WHEN price < 500 THEN 'Budget'
        WHEN price <= 2000 THEN 'Mid'
        ELSE 'Premium'
    END;
```
