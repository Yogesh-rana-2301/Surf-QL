# Top SQL Patterns to Master (Interview Focus)

This guide converts common interview questions into reusable SQL patterns.

## 1) Aggregation Pattern (GROUP BY)

Use when:

- You need summaries like count, average, total.

Core idea:

- Collapse multiple rows into one row per group.

Common use-cases:

- Average salary per department.
- Count users per city.
- Total revenue per product.

Example:

```sql
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;
```

## 2) Filtering After Aggregation (HAVING)

Use when:

- You need to filter grouped/aggregated results.

Core idea:

- `WHERE` filters rows before grouping.
- `HAVING` filters groups after grouping.

Example:

```sql
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > 50000;
```

## 3) Ranking Pattern (Window Functions)

Tools:

- `RANK()`
- `DENSE_RANK()`
- `ROW_NUMBER()`

Use when:

- Top N problems.
- Leaderboards.
- Deduplication.

Examples:

- Top 3 salaries.
- 2nd highest salary.
- Remove duplicates and keep latest row.

Example query:

```sql
SELECT
  emp_id,
  salary,
  DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```

## 4) Partitioning Pattern (PARTITION BY)

Use when:

- You want calculations within groups without collapsing rows.

Core idea:

- Group logically, but keep every original row.

Examples:

- Salary rank per department.
- Department average salary shown on every employee row.

Example:

```sql
SELECT
  emp_id,
  dept_id,
  salary,
  AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg_salary
FROM employees;
```

## 5) Top-N Per Group Pattern (Very Important)

Combination:

- `PARTITION BY` + `ROW_NUMBER()` (or `DENSE_RANK()`).

Use when:

- Problem says "Top N per category/group".

Examples:

- Top 2 students per class.
- Top selling products per region.

Example:

```sql
WITH ranked AS (
  SELECT
    student_id,
    class_id,
    marks,
    ROW_NUMBER() OVER (PARTITION BY class_id ORDER BY marks DESC) AS rn
  FROM students
)
SELECT *
FROM ranked
WHERE rn <= 2;
```

## 6) Join Pattern

Types:

- `INNER JOIN`
- `LEFT JOIN`
- `RIGHT JOIN`

Use when:

- Data is spread across multiple tables.

Core idea:

- Combine rows using relationship keys.

Examples:

- Users with their orders.
- Employees with departments.

Example:

```sql
SELECT u.user_id, u.name, o.order_id
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id;
```

## 7) Anti-Join Pattern (Very Useful)

Use when:

- You need rows that do not have a matching record.

Technique:

- `LEFT JOIN ... WHERE right_table.key IS NULL`

Examples:

- Customers who made no orders.
- Employees without managers.

Example:

```sql
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;
```

## 8) Subquery / CTE Pattern

Use when:

- Logic is multi-step.
- Query becomes hard to read in one block.

Core idea:

- Solve in steps.
- Prefer CTE for readability in interview explanations.

Example with CTE:

```sql
WITH dept_avg AS (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
)
SELECT e.emp_id, e.name, e.salary
FROM employees e
JOIN dept_avg d ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_salary;
```

## 9) Running Total / Cumulative Sum

Tool:

- `SUM(...) OVER (ORDER BY ...)`

Use when:

- Time-series totals.

Example:

- Running sales total.
- Cumulative users over time.

Example:

```sql
SELECT
  order_date,
  amount,
  SUM(amount) OVER (
    ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total
FROM orders;
```

## 10) Lag / Lead Pattern

Tools:

- `LAG()`
- `LEAD()`

Use when:

- Compare with previous or next row.

Examples:

- Day-over-day sales difference.
- Detect value change events.

Example:

```sql
SELECT
  order_date,
  amount,
  LAG(amount) OVER (ORDER BY order_date) AS prev_amount,
  amount - LAG(amount) OVER (ORDER BY order_date) AS diff
FROM daily_sales;
```

## 11) Deduplication Pattern

Tool:

- `ROW_NUMBER()`

Use when:

- Duplicate rows exist and you must keep one row (latest/best).

Examples:

- Keep latest login per user.
- Remove duplicate entries.

Example:

```sql
WITH tagged AS (
  SELECT
    user_id,
    login_time,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_time DESC) AS rn
  FROM user_logins
)
SELECT user_id, login_time
FROM tagged
WHERE rn = 1;
```

## 12) Conditional Aggregation

Use when:

- You need multiple condition-based metrics in one query.

Technique:

- `SUM(CASE WHEN condition THEN value ELSE 0 END)`

Examples:

- Count active vs inactive users.
- Revenue split by categories in one row.

Example:

```sql
SELECT
  DATE(created_at) AS dt,
  SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS active_users,
  SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) AS inactive_users
FROM users
GROUP BY DATE(created_at);
```

## 13) EXISTS / NOT EXISTS Pattern

Use when:

- You only need to check if a related row exists.

Examples:

- Users who have at least one order.
- Products never sold.

Example:

```sql
SELECT u.user_id, u.name
FROM users u
WHERE EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.user_id = u.user_id
);
```

`NOT EXISTS` version:

```sql
SELECT p.product_id, p.product_name
FROM products p
WHERE NOT EXISTS (
  SELECT 1
  FROM order_items oi
  WHERE oi.product_id = p.product_id
);
```

## 14) Self-Join Pattern

Use when:

- A table relates to itself.

Examples:

- Employee-manager mapping.
- Friend pairs/match pairs.

Example:

```sql
SELECT
  e.emp_id,
  e.name AS employee_name,
  m.emp_id AS manager_id,
  m.name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
```

## Meta Insight (Most Important)

Most SQL interview questions reduce to combinations of:

- Filtering (`WHERE`)
- Grouping (`GROUP BY`)
- Comparing rows (`WINDOW` functions)
- Combining tables (`JOIN`)

## How to Train Effectively

For every SQL question, force this process:

1. Identify the pattern:

- "This is ranking"
- "This is aggregation"
- "This is anti-join"

2. Map to tool:

- Ranking -> window function
- Summary -> `GROUP BY`
- Non-matching rows -> anti-join or `NOT EXISTS`

3. Solve, repeat, and review:

- Write query without looking.
- Compare with ideal pattern.
- Repeat until pattern recognition is automatic.
