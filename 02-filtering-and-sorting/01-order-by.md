# ORDER BY — Sorting Query Results with Precision

> **Interview Priority**: 🔴 Must Know

## What Is It?

`ORDER BY` sorts the result set of a query by one or more columns, expressions, or aliases — either ascending (`ASC`) or descending (`DESC`). It is the **only reliable way** to guarantee result order in SQL; without it, the database engine can return rows in any order it likes.

## Syntax

```sql
SELECT column1, column2, ...
FROM table_name
[WHERE condition]
ORDER BY
    column1 [ASC | DESC] [NULLS FIRST | NULLS LAST],
    column2 [ASC | DESC] [NULLS FIRST | NULLS LAST],
    ...;
```

- Default direction is `ASC` when omitted.
- Multiple columns are separated by commas; the second column breaks ties in the first, and so on.

## Key Concepts

- **Execution order**: `ORDER BY` runs *after* `SELECT`, which is why you **can** use column aliases defined in `SELECT`.
- **Column position**: You can sort by ordinal position (`ORDER BY 2 DESC`) — valid but discouraged in production because it's fragile.
- **Expression sorting**: Any valid SQL expression (e.g., `salary * 1.1`, `UPPER(name)`) is allowed.
- **NULLS FIRST / NULLS LAST**: Controls where `NULL` values land. By default in most databases, `NULL` sorts as the *largest* value (so `ASC` puts them last, `DESC` puts them first). This default varies slightly between PostgreSQL and MySQL.
- **Case sensitivity**: String sorting is collation-dependent; in some setups `'a'` and `'A'` sort identically.
- **ORDER BY in subqueries**: Has no guaranteed effect inside a subquery unless paired with `LIMIT`/`FETCH`; the outer query may re-order rows anyway.

## Examples

### 1 — Basic single-column sort (lowest salary first)

```sql
SELECT emp_id, name, salary
FROM employees
ORDER BY salary ASC;

-- Result:
-- emp_id | name  | salary
-- -------+-------+--------
--  2     | Priya | 62000
--  5     | Dev   | 78000
--  4     | Zara  | 74000
--  1     | Aman  | 85000
--  3     | Ravi  | 91000
```

### 2 — Descending sort (highest salary first)

```sql
SELECT emp_id, name, salary
FROM employees
ORDER BY salary DESC;
```

### 3 — Multiple columns (department first, then salary descending within each dept)

```sql
SELECT name, dept_id, salary
FROM employees
ORDER BY dept_id ASC, salary DESC;

-- Within Engineering (dept_id=10): Aman (85000) before Dev (78000)
-- Within HR (dept_id=20): Priya (62000) alone
-- Within Finance (dept_id=30): Ravi (91000) alone
```

### 4 — Sort by a computed expression (annual salary)

```sql
SELECT name, salary, salary * 12 AS annual_salary
FROM employees
ORDER BY salary * 12 DESC;
```

### 5 — Sort by alias (works because ORDER BY executes after SELECT)

```sql
SELECT name, salary * 12 AS annual_salary
FROM employees
ORDER BY annual_salary DESC;   -- alias is visible here
```

### 6 — Sort by ordinal position (column 2 = salary)

```sql
SELECT name, salary
FROM employees
ORDER BY 2 DESC;   -- equivalent to ORDER BY salary DESC
```

### 7 — NULLS FIRST / NULLS LAST (manager_id is NULL for top-level employees)

```sql
-- Show employees with no manager at the top
SELECT name, manager_id, salary
FROM employees
ORDER BY manager_id ASC NULLS FIRST;

-- Push NULL manager_ids to the bottom
SELECT name, manager_id, salary
FROM employees
ORDER BY manager_id ASC NULLS LAST;
```

### 8 — Sort by CASE expression (custom priority order)

```sql
-- Show Engineering employees first, then all others by salary
SELECT name, dept_id, salary
FROM employees
ORDER BY
    CASE WHEN dept_id = 10 THEN 0 ELSE 1 END ASC,
    salary DESC;
```

### 9 — Sort strings case-insensitively

```sql
SELECT name
FROM employees
ORDER BY UPPER(name) ASC;
```

## Interview Tips

1. **"Why don't you use ORDER BY inside a subquery?"** — Explain that SQL does not guarantee subquery row order is preserved by the outer query; the optimizer is free to ignore it. Always `ORDER BY` in the outermost query.
2. **Alias in ORDER BY is valid; alias in WHERE/GROUP BY is not** (in standard SQL). This trips up many candidates. PostgreSQL allows alias in `GROUP BY`; MySQL allows it too — but standard SQL does not.
3. **NULLS FIRST/LAST is PostgreSQL/Oracle syntax** — MySQL has no native `NULLS FIRST` syntax; you simulate it with `ORDER BY (manager_id IS NULL) DESC, manager_id ASC`.
4. **Performance**: Sorting large result sets without an index forces a full-table sort (filesort). Interviewers may ask how you'd optimise a slow `ORDER BY` — answer: index on the sort column(s).
5. **ORDER BY with DISTINCT / GROUP BY** — the sort column must be in the `SELECT` list when `DISTINCT` is used; this is a common gotcha.

## ❓ Practice Questions

1. Write a query to list all employees sorted by their `hire_date` from the most recently hired to the oldest. Show `name`, `hire_date`, and `salary`.

2. List all employees sorted by `dept_id` ascending, and within each department by `salary` descending. Show `name`, `dept_id`, and `salary`.

3. Some employees may have a `NULL` in `manager_id` (they are top-level managers). Write a query that lists employees sorted by `salary` descending, with employees who have no manager (`NULL` manager_id) appearing **last**.

4. Write a query that computes each employee's annual bonus as `salary * 0.10` and sorts the result from highest bonus to lowest. Use an alias `annual_bonus` and sort by that alias.

5. Write a query to retrieve employees ordered by the **length of their name** (shortest name first), then alphabetically for ties. (Hint: use `LENGTH(name)` or `LEN(name)` depending on your DB.)
