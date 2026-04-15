# SQL Window Functions Guide (Interview Focus)

This file is a practical guide to window functions for placements and interviews.

## 1) What Is a Window Function?

A window function performs a calculation across a set of rows related to the current row,
without collapsing rows like GROUP BY does.

General syntax:

```sql
FUNCTION_NAME(expression) OVER (
  [PARTITION BY col1, col2]
  [ORDER BY col3]
  [ROWS/RANGE frame_clause]
)
```

## 2) Why Interviewers Ask Window Functions

- They test real SQL skill beyond basic SELECT/JOIN.
- They solve ranking, running totals, and previous/next row problems.
- They are common in analytics and reporting roles.

## 3) Core Building Blocks

### OVER()

Defines the window where function is applied.

### PARTITION BY

Splits rows into groups (like logical buckets) before calculation.

### ORDER BY inside OVER

Defines order within each partition.

### Frame Clause (ROWS/RANGE)

Defines which rows around current row are included.

## 4) Most Important Window Functions

### ROW_NUMBER()

Assigns unique sequential number per partition.

```sql
SELECT
  emp_id,
  dept_id,
  salary,
  ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
FROM employees;
```

Use case: Top 1 row per group (after filtering rn = 1).

### RANK()

Same rank for ties, skips next rank numbers.

```sql
SELECT
  emp_id,
  dept_id,
  salary,
  RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk
FROM employees;
```

Example: salaries [100, 100, 90] -> ranks [1, 1, 3]

### DENSE_RANK()

Same rank for ties, does not skip rank numbers.

```sql
SELECT
  emp_id,
  dept_id,
  salary,
  DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS drnk
FROM employees;
```

Example: salaries [100, 100, 90] -> ranks [1, 1, 2]

### NTILE(n)

Splits ordered rows into n buckets.

```sql
SELECT
  emp_id,
  salary,
  NTILE(4) OVER (ORDER BY salary DESC) AS quartile
FROM employees;
```

Use case: quartile analysis.

## 5) Aggregate Window Functions

### Running Total

```sql
SELECT
  order_id,
  order_date,
  amount,
  SUM(amount) OVER (
    ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total
FROM orders;
```

### Moving Average (Last 3 Rows)

```sql
SELECT
  order_id,
  order_date,
  amount,
  AVG(amount) OVER (
    ORDER BY order_date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_avg_3
FROM orders;
```

### Partition-Level Totals (without collapsing rows)

```sql
SELECT
  emp_id,
  dept_id,
  salary,
  SUM(salary) OVER (PARTITION BY dept_id) AS dept_total_salary,
  AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg_salary
FROM employees;
```

## 6) Value Comparison Functions

### LAG()

Get previous row value.

```sql
SELECT
  order_date,
  amount,
  LAG(amount, 1) OVER (ORDER BY order_date) AS prev_amount,
  amount - LAG(amount, 1) OVER (ORDER BY order_date) AS diff_from_prev
FROM orders;
```

### LEAD()

Get next row value.

```sql
SELECT
  order_date,
  amount,
  LEAD(amount, 1) OVER (ORDER BY order_date) AS next_amount
FROM orders;
```

### FIRST_VALUE() and LAST_VALUE()

```sql
SELECT
  emp_id,
  dept_id,
  salary,
  FIRST_VALUE(salary) OVER (
    PARTITION BY dept_id
    ORDER BY salary DESC
  ) AS top_salary_in_dept
FROM employees;
```

Note: LAST_VALUE often needs an explicit frame to behave as expected.

## 7) Interview Pattern: Top N Per Group

Question: Get top 3 salaries in each department.

```sql
WITH ranked AS (
  SELECT
    emp_id,
    dept_id,
    salary,
    DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dr
  FROM employees
)
SELECT *
FROM ranked
WHERE dr <= 3;
```

## 8) Interview Pattern: Latest Record Per User

Question: Get each customer's latest order.

```sql
WITH latest_orders AS (
  SELECT
    customer_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY order_date DESC
    ) AS rn
  FROM orders
)
SELECT customer_id, order_id, order_date
FROM latest_orders
WHERE rn = 1;
```

## 9) ROWS vs RANGE (Common Theory Question)

- ROWS: physical row count based frame.
- RANGE: value-based frame using ORDER BY value semantics.

In interviews, prefer ROWS for predictable behavior unless RANGE is specifically needed.

## 10) Common Mistakes

- Forgetting ORDER BY inside OVER when order-dependent function is used.
- Using GROUP BY when row-level detail is needed.
- Confusing RANK and DENSE_RANK.
- Ignoring frame clause when using LAST_VALUE.
- Filtering directly on window alias in same SELECT level (use CTE/subquery).

## 11) Window Functions vs GROUP BY

- GROUP BY reduces rows (one row per group).
- Window functions keep original rows and add analytic columns.

Example: You can show each employee salary plus department average salary in one result set using window functions.

## 12) Interview Quick Recap

- Start with: PARTITION BY (group), ORDER BY (sequence), then function.
- Use ROW_NUMBER for dedup/latest-row problems.
- Use DENSE_RANK for top N per group.
- Use LAG/LEAD for previous-next comparisons.
- Use SUM OVER for running totals.
