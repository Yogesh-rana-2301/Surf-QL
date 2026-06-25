# Date Functions — Working with Dates and Times in SQL

> **Interview Priority**: 🔴 Must Know

## What Is It?

Date functions let you query, compare, format, and calculate with date and time values. They're essential in analytics and reporting interviews — nearly every real-world dataset has timestamps, and interviewers expect you to filter by date ranges, calculate durations, group by month/year, and format output cleanly.

---

## Syntax

```sql
-- General patterns
SELECT DATE_FUNCTION(date_column) FROM table;
SELECT DATE_ADD(date_column, INTERVAL n UNIT) FROM table;
SELECT DATEDIFF(date1, date2) FROM table;
```

---

## Key Concepts

- **DATE vs DATETIME vs TIMESTAMP**: `DATE` stores only the date (YYYY-MM-DD). `DATETIME` stores date + time. `TIMESTAMP` is also date + time but is timezone-aware and stored in UTC.
- Date arithmetic differs significantly across MySQL, PostgreSQL, and SQL Server — know at least two dialects.
- `CURRENT_DATE` returns today's date without a time component. `NOW()` returns the current datetime with time.
- When comparing dates in `WHERE`, ensure the column is not wrapped in a function — this can prevent index usage.
- `EXTRACT` is ANSI SQL and the most portable way to pull year/month/day from a date.

---

## Examples

### 1. CURRENT_DATE / NOW() / GETDATE() — Get today's date or datetime

```sql
-- Today's date (no time component)
SELECT CURRENT_DATE;                  -- ANSI SQL; MySQL, PostgreSQL
SELECT CURDATE();                     -- MySQL only
SELECT CAST(GETDATE() AS DATE);       -- SQL Server

-- Current datetime (includes time)
SELECT NOW();                         -- MySQL, PostgreSQL
SELECT GETDATE();                     -- SQL Server
SELECT CURRENT_TIMESTAMP;             -- ANSI SQL, all dialects

-- Practical use: mark records as of today
SELECT name, hire_date,
       CURRENT_DATE AS today
FROM employees;

-- Find employees hired before today (sanity check)
SELECT name, hire_date
FROM employees
WHERE hire_date < CURRENT_DATE;
```

---

### 2. DATE_ADD / DATE_SUB / DATEADD — Add or subtract time intervals

```sql
-- MySQL / PostgreSQL: DATE_ADD with INTERVAL
SELECT name, hire_date,
       DATE_ADD(hire_date, INTERVAL 1 YEAR)  AS one_year_later,
       DATE_SUB(hire_date, INTERVAL 30 DAY)  AS thirty_before_hire
FROM employees;

-- MySQL shorthand
SELECT hire_date + INTERVAL 6 MONTH AS six_months_later
FROM employees;

-- PostgreSQL: use interval arithmetic directly
SELECT hire_date + INTERVAL '90 days' AS probation_end
FROM employees;

-- SQL Server: DATEADD(unit, number, date)
SELECT DATEADD(DAY, 90, hire_date) AS probation_end FROM employees;

-- Practical: find orders placed within the last 30 days
SELECT order_id, customer_id, amount, order_date
FROM orders
WHERE order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY);
-- SQL Server: WHERE order_date >= DATEADD(DAY, -30, GETDATE())
```

---

### 3. DATEDIFF — Calculate the difference between two dates

```sql
-- MySQL: DATEDIFF(later_date, earlier_date) → number of days
SELECT name,
       hire_date,
       DATEDIFF(CURRENT_DATE, hire_date) AS days_employed
FROM employees;
-- Aman hired 2019-03-15 → 2650+ days

-- Find employees hired more than 5 years ago
SELECT name, hire_date
FROM employees
WHERE DATEDIFF(CURRENT_DATE, hire_date) > 5 * 365;

-- Days between order date and today (backlog analysis)
SELECT order_id, status, order_date,
       DATEDIFF(CURRENT_DATE, order_date) AS days_pending
FROM orders
WHERE status = 'Pending'
ORDER BY days_pending DESC;

-- SQL Server / PostgreSQL use DATEDIFF differently:
-- SQL Server: DATEDIFF(unit, start_date, end_date)
SELECT DATEDIFF(DAY, hire_date, GETDATE()) AS days_employed FROM employees;

-- PostgreSQL: date subtraction returns an interval
SELECT name, (CURRENT_DATE - hire_date) AS days_employed FROM employees;
-- Or: EXTRACT(DAY FROM age(CURRENT_DATE, hire_date))
```

> **Interview note**: Always clarify the argument order — MySQL's `DATEDIFF` takes `(end, start)` while SQL Server takes `(unit, start, end)`.

---

### 4. EXTRACT / YEAR() / MONTH() / DAY() — Pull parts of a date

```sql
-- ANSI SQL: EXTRACT (works in MySQL and PostgreSQL)
SELECT name, hire_date,
       EXTRACT(YEAR  FROM hire_date) AS hire_year,
       EXTRACT(MONTH FROM hire_date) AS hire_month,
       EXTRACT(DAY   FROM hire_date) AS hire_day
FROM employees;

-- MySQL shorthand functions
SELECT name,
       YEAR(hire_date)    AS hire_year,
       MONTH(hire_date)   AS hire_month,
       DAY(hire_date)     AS hire_day,
       QUARTER(hire_date) AS hire_quarter,
       DAYOFWEEK(hire_date) AS day_of_week  -- 1=Sunday, 7=Saturday
FROM employees;

-- Practical: count employees hired per year
SELECT YEAR(hire_date) AS hire_year,
       COUNT(*) AS total_hired
FROM employees
GROUP BY YEAR(hire_date)
ORDER BY hire_year;

-- Monthly order totals
SELECT YEAR(order_date)  AS yr,
       MONTH(order_date) AS mo,
       SUM(amount)       AS monthly_revenue,
       COUNT(*)          AS order_count
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY yr, mo;

-- SQL Server equivalent
SELECT YEAR(order_date) AS yr, MONTH(order_date) AS mo,
       SUM(amount) AS monthly_revenue
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date);
```

---

### 5. DATE_FORMAT / TO_CHAR — Format date as a string

```sql
-- MySQL: DATE_FORMAT(date, format_string)
SELECT name, hire_date,
       DATE_FORMAT(hire_date, '%d-%b-%Y') AS formatted_date
FROM employees;
-- 2019-03-15 → 15-Mar-2019

-- Common MySQL format codes:
-- %Y = 4-digit year, %y = 2-digit year
-- %m = 2-digit month, %b = abbreviated month name (Jan, Feb...)
-- %M = full month name
-- %d = 2-digit day, %e = day without leading zero
-- %H = hour (24h), %i = minutes, %s = seconds

SELECT DATE_FORMAT(order_date, '%Y-%m') AS month_label,
       SUM(amount) AS revenue
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month_label;
-- Groups by "2024-01", "2024-02", etc.

-- PostgreSQL: TO_CHAR(date, format)
SELECT name, TO_CHAR(hire_date, 'DD-Mon-YYYY') AS formatted_date
FROM employees;
-- TO_CHAR format codes: YYYY, MM, DD, Mon, Month, Day, HH24, MI, SS

-- SQL Server: FORMAT(date, format_string)
SELECT FORMAT(hire_date, 'dd-MMM-yyyy') AS formatted_date FROM employees;
-- Or: CONVERT(VARCHAR, hire_date, 106) -- British format DD Mon YYYY
```

---

### 6. DATE_TRUNC — Truncate a date to a time boundary

`DATE_TRUNC` rounds a datetime down to the start of the given unit (month, year, week, etc.). Most useful in PostgreSQL.

```sql
-- PostgreSQL: DATE_TRUNC('unit', date)
SELECT DATE_TRUNC('month', order_date) AS month_start,
       SUM(amount) AS revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month_start;
-- All orders in June 2024 group under '2024-06-01 00:00:00'

-- Truncate to year
SELECT DATE_TRUNC('year', hire_date) AS year_start,
       COUNT(*) AS hired_count
FROM employees
GROUP BY DATE_TRUNC('year', hire_date);

-- MySQL equivalent: use DATE_FORMAT or explicit year/month grouping
-- MySQL doesn't have DATE_TRUNC natively, but:
SELECT DATE_FORMAT(order_date, '%Y-%m-01') AS month_start,
       SUM(amount) AS revenue
FROM orders
GROUP BY month_start;

-- SQL Server equivalent: DATETRUNC (SQL Server 2022+)
SELECT DATETRUNC(MONTH, order_date) AS month_start,
       SUM(amount) AS revenue
FROM orders
GROUP BY DATETRUNC(MONTH, order_date);
-- Older SQL Server: DATEFROMPARTS(YEAR(d), MONTH(d), 1)
```

---

### 7. TIMESTAMPDIFF — Difference between dates in a specific unit

MySQL's `TIMESTAMPDIFF` is more flexible than `DATEDIFF` — you specify the unit.

```sql
-- Syntax: TIMESTAMPDIFF(unit, start, end)
-- Units: SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR

-- Employee tenure in full years (age calculation)
SELECT name, hire_date,
       TIMESTAMPDIFF(YEAR, hire_date, CURRENT_DATE) AS tenure_years
FROM employees;
-- Aman (hired 2019-03-15) → 7 years

-- Employee tenure in months
SELECT name,
       TIMESTAMPDIFF(MONTH, hire_date, CURRENT_DATE) AS tenure_months
FROM employees;

-- Days since last order per customer
SELECT c.name AS customer,
       MAX(o.order_date) AS last_order,
       TIMESTAMPDIFF(DAY, MAX(o.order_date), CURRENT_DATE) AS days_since_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY days_since_order DESC;

-- PostgreSQL equivalent: AGE() function
SELECT name,
       AGE(CURRENT_DATE, hire_date) AS tenure,        -- interval type
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS tenure_years
FROM employees;

-- SQL Server equivalent:
SELECT name,
       DATEDIFF(YEAR, hire_date, GETDATE()) AS tenure_years
FROM employees;
```

---

## Common Interview Date Problems

### Problem 1: Employees Hired in the Last 90 Days

```sql
-- MySQL
SELECT name, hire_date,
       DATEDIFF(CURRENT_DATE, hire_date) AS days_ago
FROM employees
WHERE hire_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
ORDER BY hire_date DESC;

-- PostgreSQL
SELECT name, hire_date
FROM employees
WHERE hire_date >= CURRENT_DATE - INTERVAL '90 days';

-- SQL Server
SELECT name, hire_date
FROM employees
WHERE hire_date >= DATEADD(DAY, -90, GETDATE());
```

---

### Problem 2: Monthly Order Totals

```sql
-- Summarize orders by month and year, show revenue and count
SELECT
    YEAR(order_date)            AS yr,
    MONTH(order_date)           AS mo,
    DATE_FORMAT(order_date, '%b %Y') AS month_label,
    COUNT(*)                    AS order_count,
    SUM(amount)                 AS total_revenue,
    AVG(amount)                 AS avg_order_value
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY yr, mo;

-- With running total using window function
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(amount) AS monthly_revenue,
    SUM(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS cumulative_revenue
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
```

---

### Problem 3: Employee Tenure in Years

```sql
-- Basic tenure
SELECT
    name,
    hire_date,
    TIMESTAMPDIFF(YEAR, hire_date, CURRENT_DATE) AS tenure_years
FROM employees
ORDER BY tenure_years DESC;

-- Categorize tenure
SELECT name, hire_date,
       TIMESTAMPDIFF(YEAR, hire_date, CURRENT_DATE) AS tenure_years,
       CASE
           WHEN TIMESTAMPDIFF(YEAR, hire_date, CURRENT_DATE) < 1  THEN 'New Hire'
           WHEN TIMESTAMPDIFF(YEAR, hire_date, CURRENT_DATE) < 3  THEN 'Junior'
           WHEN TIMESTAMPDIFF(YEAR, hire_date, CURRENT_DATE) < 7  THEN 'Mid-Level'
           ELSE 'Senior'
       END AS tenure_category
FROM employees;
```

---

### Problem 4: Year-Over-Year Revenue Comparison

```sql
-- Compare this year vs last year using conditional aggregation
SELECT
    SUM(CASE WHEN YEAR(order_date) = YEAR(CURRENT_DATE)     THEN amount ELSE 0 END) AS this_year,
    SUM(CASE WHEN YEAR(order_date) = YEAR(CURRENT_DATE) - 1 THEN amount ELSE 0 END) AS last_year
FROM orders;

-- Using LAG for month-over-month comparison
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(amount) AS revenue,
    LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS prev_month_revenue,
    SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS mom_change
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m');
```

---

## Dialect Quick Reference

| Task | MySQL | PostgreSQL | SQL Server |
|---|---|---|---|
| Today's date | `CURDATE()` / `CURRENT_DATE` | `CURRENT_DATE` | `CAST(GETDATE() AS DATE)` |
| Now (datetime) | `NOW()` | `NOW()` | `GETDATE()` |
| Add days | `DATE_ADD(d, INTERVAL n DAY)` | `d + INTERVAL 'n days'` | `DATEADD(DAY, n, d)` |
| Subtract days | `DATE_SUB(d, INTERVAL n DAY)` | `d - INTERVAL 'n days'` | `DATEADD(DAY, -n, d)` |
| Days between | `DATEDIFF(d2, d1)` | `d2 - d1` (→ integer) | `DATEDIFF(DAY, d1, d2)` |
| Year from date | `YEAR(d)` | `EXTRACT(YEAR FROM d)` | `YEAR(d)` |
| Month from date | `MONTH(d)` | `EXTRACT(MONTH FROM d)` | `MONTH(d)` |
| Format date | `DATE_FORMAT(d, '%Y-%m')` | `TO_CHAR(d, 'YYYY-MM')` | `FORMAT(d, 'yyyy-MM')` |
| Truncate to month | `DATE_FORMAT(d,'%Y-%m-01')` | `DATE_TRUNC('month', d)` | `DATETRUNC(MONTH, d)` |
| Diff in years | `TIMESTAMPDIFF(YEAR, d1, d2)` | `EXTRACT(YEAR FROM AGE(d2,d1))` | `DATEDIFF(YEAR, d1, d2)` |

---

## Interview Tips

1. **Know `DATEDIFF` argument order by dialect** — MySQL is `DATEDIFF(end, start)`, SQL Server is `DATEDIFF(unit, start, end)`. Getting this backwards is a common mistake interviewers watch for.

2. **Avoid wrapping indexed date columns in functions in `WHERE`** — `WHERE YEAR(hire_date) = 2023` prevents index use. Better: `WHERE hire_date >= '2023-01-01' AND hire_date < '2024-01-01'`.

3. **`DATE_TRUNC` is the clean way to group by month** — In PostgreSQL interviews, use `DATE_TRUNC('month', order_date)` for monthly grouping rather than `EXTRACT` on year and month separately.

4. **TIMESTAMPDIFF vs DATEDIFF** — Be ready to explain that `DATEDIFF` only returns days in MySQL, while `TIMESTAMPDIFF` lets you specify the unit (YEAR, MONTH, DAY, etc.). For age/tenure, `TIMESTAMPDIFF(YEAR, ...)` is more accurate.

5. **Running monthly totals** — Combining `GROUP BY` on month with `SUM(...) OVER (ORDER BY month)` as a window function shows you can bridge aggregation and analytics — a strong answer in analytics interviews.

---

## ❓ Practice Questions

1. Write a query to find all employees who were **hired in the last 2 years** from today. Display their name, hire date, and the number of days they have been employed.

2. Write a query to show **total order revenue by month** for the orders table. Format the month as `'Jan 2024'` style. Order by date chronologically.

3. Write a query to calculate each employee's **tenure in years and months** (e.g., "4 years, 3 months"). Display their name, hire date, and tenure. (Hint: use `TIMESTAMPDIFF` twice — once for years, once for remaining months.)

4. Write a query to find customers who have **not placed any orders in the last 180 days** (i.e., their most recent order was more than 6 months ago, or they have no orders at all). Show customer name and their last order date (NULL if no orders).

5. Write a query to show a **year-over-year comparison** of total order revenue — one column for the current year and one for the previous year, on the same row. Use conditional aggregation.
