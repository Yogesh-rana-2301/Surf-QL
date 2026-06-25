# Nth Highest Salary — The Most Asked SQL Interview Question

> **Interview Priority**: 🔴 Must Know

## What Is It?

"Find the Nth highest salary" is the single most common SQL interview question across all levels — junior, mid, and senior. It tests your knowledge of subqueries, window functions, and how your database handles duplicate values. You need to know **all approaches** and when to use each.

---

## The Critical Problem with Duplicates

Before diving into solutions, understand this:

```
employees table salaries:
Ravi   → 91,000   ← 1st highest
Aman   → 85,000   ← 2nd highest
Dev    → 85,000   ← also 85,000 (tie!)
Zara   → 74,000   ← 3rd? 4th? depends on approach
Priya  → 62,000
```

- **ROW_NUMBER**: assigns 1, 2, 3, 4, 5 — no ties. One row per number.
- **DENSE_RANK**: assigns 1, 2, 2, 3, 4 — ties share a rank, no gaps.
- **RANK**: assigns 1, 2, 2, 4, 5 — ties share a rank, gaps after ties.

When the question says "2nd highest salary", clarify: does 85,000 (shared by two people) count as 2nd, or do both people want the same rank? **DENSE_RANK** is almost always the correct interpretation in interviews.

---

## Approach 1: LIMIT + OFFSET

Simple and readable. Works in MySQL and PostgreSQL.

```sql
-- Nth highest salary (N=2 for 2nd highest)
-- OFFSET n-1 skips the top n-1 rows
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 1;   -- 2nd highest: OFFSET = 2-1 = 1
                     -- 3rd highest: OFFSET 2
                     -- Nth highest: OFFSET N-1
```

```sql
-- For N=3 (3rd highest)
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 2;

-- Note: DISTINCT ensures duplicate salaries are treated as one rank
-- Without DISTINCT: if two people have 85000, OFFSET 1 still gives 85000
```

**Limitations**:
- `LIMIT/OFFSET` is not supported in SQL Server (use `FETCH NEXT` / `OFFSET` with `ORDER BY`).
- SQL Server equivalent:
```sql
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
OFFSET 1 ROWS FETCH NEXT 1 ROW ONLY;  -- 2nd highest
```
- Does not handle the "what if there are fewer than N distinct salaries?" case gracefully — returns empty result.

---

## Approach 2: Subquery with MAX (Classic Interview Approach)

"Find the maximum salary that is less than the maximum excluding the top N-1 values."

```sql
-- 2nd highest salary using nested MAX
SELECT MAX(salary) AS second_highest
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);
-- Finds MAX of all salaries below the top salary
-- Result: 85000
```

```sql
-- Generalize to Nth highest using correlated subquery
-- "Find the max salary such that exactly N-1 salaries are greater than it"
SELECT MAX(salary) AS nth_highest
FROM employees
WHERE salary < ALL (
    SELECT salary FROM employees
    ORDER BY salary DESC
    LIMIT N-1   -- Replace N with the actual number
);

-- More portable version (works without LIMIT in subquery):
-- N=3: Find max salary where at least 2 distinct higher salaries exist
SELECT MAX(salary) AS third_highest
FROM employees
WHERE salary NOT IN (
    SELECT salary FROM employees
    ORDER BY salary DESC
    LIMIT 2    -- exclude top 2
);
```

**The classic correlated subquery version** (works in all dialects):

```sql
-- Nth highest: find salary where exactly (N-1) salaries are STRICTLY higher
-- N=2: second highest
SELECT salary
FROM employees e1
WHERE 1 = (              -- exactly 1 salary is higher than this one
    SELECT COUNT(DISTINCT salary)
    FROM employees e2
    WHERE e2.salary > e1.salary
);
```

```sql
-- Generalized for any N: change the WHERE to (N-1)
-- N=3: third highest
SELECT salary
FROM employees e1
WHERE 2 = (
    SELECT COUNT(DISTINCT salary)
    FROM employees e2
    WHERE e2.salary > e1.salary
);
-- This finds the salary where exactly 2 distinct salaries are higher → 3rd highest
```

> This approach is elegant but slower on large tables — it's O(n²). Mention this when asked.

---

## Approach 3: DENSE_RANK Window Function ⭐ Best Approach

This is the **most readable, most correct, and most impressive** answer in an interview.

```sql
-- Step 1: rank all employees by salary with DENSE_RANK
WITH salary_ranks AS (
    SELECT
        emp_id,
        name,
        salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
)
-- Step 2: filter for the Nth rank
SELECT emp_id, name, salary
FROM salary_ranks
WHERE rnk = 2;   -- Change to N for Nth highest
```

```sql
-- Result for N=2:
-- Aman  | 85000 | rank 2
-- Dev   | 85000 | rank 2
-- Both rows returned — both employees with the 2nd-highest salary
```

Why DENSE_RANK is best:
- Returns **all employees** with that salary (ties handled correctly)
- No missing ranks between ties (unlike RANK which has gaps)
- Very readable — logic is explicit and easy to verify
- Works in MySQL 8+, PostgreSQL, SQL Server, Oracle

```sql
-- Demonstrating the difference in rank functions
SELECT name, salary,
       ROW_NUMBER()  OVER (ORDER BY salary DESC) AS row_num,
       RANK()        OVER (ORDER BY salary DESC) AS rnk,
       DENSE_RANK()  OVER (ORDER BY salary DESC) AS dense_rnk
FROM employees;

-- Result:
-- Ravi  | 91000 | row_num=1 | rank=1 | dense_rank=1
-- Aman  | 85000 | row_num=2 | rank=2 | dense_rank=2
-- Dev   | 85000 | row_num=3 | rank=2 | dense_rank=2
-- Zara  | 74000 | row_num=4 | rank=4 | dense_rank=3  ← rank skips 3!
-- Priya | 62000 | row_num=5 | rank=5 | dense_rank=4
```

---

## Approach 4: ROW_NUMBER Window Function

Use when you want **exactly one row** per rank, even for ties.

```sql
WITH ranked AS (
    SELECT
        emp_id,
        name,
        salary,
        ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT emp_id, name, salary
FROM ranked
WHERE rn = 2;
-- Returns only ONE row even if two employees have the same salary
-- Which one? Arbitrary — depends on internal ordering
```

**When to use ROW_NUMBER instead of DENSE_RANK**:
- You need exactly N rows (e.g., "return exactly 1 result, pick any for ties")
- Deduplication: you want to eliminate ties by choosing one record
- Pagination: you want the exact 5th through 10th records in a ranked list

---

## Approach 5: NOT IN / NOT EXISTS

Remove the top N-1 salaries and take the MAX of what remains.

```sql
-- 2nd highest: exclude the max salary, take max of the rest
SELECT MAX(salary) AS second_highest
FROM employees
WHERE salary NOT IN (
    SELECT MAX(salary) FROM employees
);
```

```sql
-- Nth highest: exclude top (N-1) distinct salaries
-- N=3: exclude top 2 highest distinct salaries
SELECT MAX(salary) AS third_highest
FROM employees
WHERE salary NOT IN (
    SELECT DISTINCT salary
    FROM employees
    ORDER BY salary DESC
    LIMIT 2   -- Exclude top 2
);
```

```sql
-- NOT EXISTS approach (safer with NULLs):
SELECT DISTINCT e1.salary
FROM employees e1
WHERE NOT EXISTS (
    SELECT 1 FROM (
        SELECT DISTINCT salary
        FROM employees
        ORDER BY salary DESC
        LIMIT 1   -- N-1 = 1 for 2nd highest
    ) top_salaries
    WHERE top_salaries.salary = e1.salary
)
ORDER BY e1.salary DESC
LIMIT 1;
```

> **Warning**: `NOT IN` with a subquery that returns NULLs produces an empty result set due to three-valued logic. Always use `NOT EXISTS` or ensure the subquery excludes NULLs.

---

## Approach 6: Nth Highest WITHIN a Department

This adds `PARTITION BY` — a common follow-up question.

```sql
-- Top 2 earners per department using DENSE_RANK + PARTITION BY
WITH dept_ranked AS (
    SELECT
        e.emp_id,
        e.name,
        d.dept_name,
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY e.dept_id          -- reset ranking per department
            ORDER BY e.salary DESC
        ) AS dept_rank
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
)
SELECT dept_name, name, salary, dept_rank
FROM dept_ranked
WHERE dept_rank <= 2
ORDER BY dept_name, dept_rank;
```

```sql
-- 2nd highest salary WITHIN each department specifically
WITH dept_ranked AS (
    SELECT
        e.name,
        d.dept_name,
        e.salary,
        DENSE_RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS rnk
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
)
SELECT dept_name, name, salary
FROM dept_ranked
WHERE rnk = 2;
-- Shows the 2nd-highest earner(s) in each department
-- Departments with only one salary → no rows returned (no 2nd rank exists)
```

---

## Handling the "No Nth Salary Exists" Edge Case

What if there are fewer than N distinct salaries? Return NULL instead of nothing.

```sql
-- Return NULL if the Nth highest doesn't exist
SELECT (
    SELECT DISTINCT salary
    FROM employees
    ORDER BY salary DESC
    LIMIT 1 OFFSET 1   -- N-1 = 1 for 2nd highest
) AS second_highest_salary;
-- Returns NULL if there's no 2nd distinct salary
```

```sql
-- With DENSE_RANK (graceful handling):
WITH salary_ranks AS (
    SELECT DISTINCT salary,
           DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT salary AS second_highest
FROM salary_ranks
WHERE rnk = 2;
-- Empty result set if doesn't exist — interviewers may ask you to wrap in COALESCE:

SELECT COALESCE(
    (SELECT salary FROM salary_ranks WHERE rnk = 2),
    NULL
) AS second_highest;
```

---

## Comparison Summary

| Approach | Handles Ties | Works Without Window Functions | Readable | Dialect |
|---|---|---|---|---|
| LIMIT + OFFSET | With DISTINCT | ✅ Yes | ✅ | MySQL, PostgreSQL |
| MAX + subquery | ✅ Yes | ✅ Yes | 🟡 Medium | All |
| DENSE_RANK | ✅ Yes (all tied rows) | ❌ Needs window fn | ✅ Best | MySQL 8+, PG, SS |
| ROW_NUMBER | ❌ Arbitrary pick | ❌ Needs window fn | ✅ | MySQL 8+, PG, SS |
| NOT IN / NOT EXISTS | With DISTINCT | ✅ Yes | 🔴 Complex | All (careful w/ NULL) |
| PARTITION BY | ✅ Per group | ❌ Needs window fn | ✅ | MySQL 8+, PG, SS |

---

## Interview Tips

1. **Lead with DENSE_RANK** — Always present DENSE_RANK as your primary answer. Then mention LIMIT/OFFSET and the correlated subquery as alternatives. This shows you know multiple approaches.

2. **Clarify the tie-handling question** — Asking "should employees with equal salaries share the same rank?" shows maturity. DENSE_RANK is the expected answer for "rank properly."

3. **Know the NULL trap** — If asked about `NOT IN`, mention that if the subquery returns a NULL, `NOT IN` will return no rows. This is a common gotcha interviewers test.

4. **RANK vs DENSE_RANK gap** — `RANK()` skips numbers after ties (1,2,2,4). `DENSE_RANK()` does not (1,2,2,3). For salary ranking, DENSE_RANK is almost always correct.

5. **Follow-up: within a department** — Be ready to add `PARTITION BY dept_id` immediately after giving the basic answer. The follow-up question is almost guaranteed.

---

## ❓ Practice Questions

1. Write a query to find the **3rd highest salary** in the `employees` table using the `DENSE_RANK` window function. Return the employee name(s), department, and salary.

2. Write a query to find the **2nd highest salary per department**. If a department has only one unique salary (or only one employee), exclude it from the results.

3. Using **only subqueries** (no window functions), find the **4th highest salary** across all employees. Explain how your query handles duplicate salaries.

4. Write a query to find all employees who earn the **2nd highest salary in the company**. If two or more employees share that salary value, return all of them. Show name, department name, and salary.

5. Write a query using `ROW_NUMBER` to find the **top-earning employee in each department**. Then rewrite it using `DENSE_RANK`. Explain when the results would differ between the two approaches.
