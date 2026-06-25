# Recursive CTEs — Traversing Hierarchies and Trees

> **Interview Priority**: 🔴 Must Know

## What Is It?

A **Recursive CTE** uses `WITH RECURSIVE` (standard SQL) to define a query that **references itself**, enabling iteration over hierarchical or graph-structured data. Classic use cases include employee-manager chains, category trees, bill-of-materials, and generating number sequences — all patterns that require a variable-depth loop impossible with ordinary `SELECT` statements.

---

## Syntax

```sql
WITH RECURSIVE cte_name AS (

    -- 1. ANCHOR MEMBER: the starting point (non-recursive, runs once)
    SELECT ...
    FROM   base_table
    WHERE  starting_condition

    UNION ALL

    -- 2. RECURSIVE MEMBER: references the CTE itself
    SELECT ...
    FROM   base_table
    JOIN   cte_name ON join_condition   -- ← self-reference
    WHERE  termination_condition        -- ← prevents infinite loop

)
SELECT * FROM cte_name;
```

### The Three Mandatory Parts

| Part | Role |
|------|------|
| **Anchor member** | Produces the initial seed rows — runs exactly once |
| **`UNION ALL`** | Combines anchor output with each recursive iteration |
| **Recursive member** | Joins the CTE's current output back to the base table, extending the result |

The engine repeats the recursive member until it produces **zero new rows** — that is the natural termination condition. If it never produces zero rows, you get infinite recursion.

---

## Key Concepts

### 1 · Execution Model — How It Actually Runs

```
Step 0 (Anchor):   Run anchor → produce rows R₀
Step 1 (Recursive): Join R₀ to base_table → produce rows R₁
Step 2 (Recursive): Join R₁ to base_table → produce rows R₂
...
Step N (Recursive): Join Rₙ₋₁ to base_table → produce 0 rows → STOP

Final result: R₀ UNION ALL R₁ UNION ALL R₂ ... UNION ALL Rₙ₋₁
```

### 2 · Infinite Recursion Risk

If the recursive member always produces rows (e.g., circular references in data, or a missing termination condition), the query runs forever. Databases protect against this with:

- **MySQL:** `@@cte_max_recursion_depth` — default 1000. Set with `SET SESSION cte_max_recursion_depth = 500;`
- **SQL Server:** `MAXRECURSION` query hint — `OPTION (MAXRECURSION 100)`. Default 100; set to 0 for unlimited (dangerous).
- **PostgreSQL:** No hard default limit; relies on the termination condition. Use `WHERE depth < N` as a safety guard.

### 3 · UNION ALL vs UNION

Almost always use `UNION ALL` — `UNION` (without `ALL`) requires deduplication at every step, which is both expensive and often semantically wrong for hierarchical traversal (the same node can be visited multiple times legitimately in some graph scenarios, but for trees it's fine either way; `UNION ALL` is faster).

### 4 · Tracking Depth and Path

It is good practice to track the **depth** (level in the hierarchy) and the **path** (string of ancestors) in the recursive CTE. These are computed columns updated at each iteration:

```sql
-- Depth column
level + 1 AS level

-- Path column (breadcrumb trail)
CONCAT(path, ' → ', child_name) AS path
```

---

## Examples

### Example 1 — Employee–Manager Hierarchy: All Levels

**Schema reminder:** `employees(emp_id, name, manager_id, ...)`. A `NULL` `manager_id` indicates a top-level employee (CEO / root).

```sql
WITH RECURSIVE emp_hierarchy AS (

    -- ANCHOR: start from the top-level (no manager)
    SELECT emp_id,
           name,
           manager_id,
           0           AS level,
           name        AS path
    FROM   employees
    WHERE  manager_id IS NULL

    UNION ALL

    -- RECURSIVE: find each employee's direct reports
    SELECT e.emp_id,
           e.name,
           e.manager_id,
           eh.level + 1                              AS level,
           CONCAT(eh.path, ' → ', e.name)            AS path
    FROM   employees      e
    JOIN   emp_hierarchy  eh ON e.manager_id = eh.emp_id

)
SELECT emp_id,
       name,
       level,
       path
FROM   emp_hierarchy
ORDER  BY level, name;
```

**Sample output:**

| emp_id | name  | level | path                        |
|--------|-------|-------|-----------------------------|
| 1      | Alice | 0     | Alice                       |
| 2      | Ravi  | 1     | Alice → Ravi                |
| 3      | Aman  | 2     | Alice → Ravi → Aman         |
| 4      | Dev   | 2     | Alice → Ravi → Dev          |
| 5      | Priya | 1     | Alice → Priya               |

---

### Example 2 — Find All Direct and Indirect Reports Under a Specific Manager

A common interview question: *"Write a query to find everyone who reports (directly or indirectly) to manager_id = 2."*

```sql
WITH RECURSIVE reports_under AS (

    -- ANCHOR: direct reports of manager emp_id = 2
    SELECT emp_id,
           name,
           manager_id,
           1 AS level
    FROM   employees
    WHERE  manager_id = 2

    UNION ALL

    -- RECURSIVE: their reports, and their reports, etc.
    SELECT e.emp_id,
           e.name,
           e.manager_id,
           ru.level + 1
    FROM   employees     e
    JOIN   reports_under ru ON e.manager_id = ru.emp_id

)
SELECT emp_id, name, level
FROM   reports_under
ORDER  BY level, name;
```

This returns every person in Ravi's sub-tree regardless of depth — something impossible without recursion or application-level loops.

---

### Example 3 — Generating a Number Sequence (Non-hierarchy Use Case)

Recursive CTEs aren't only for hierarchies — they can generate sequences:

```sql
WITH RECURSIVE number_series AS (
    SELECT 1 AS n           -- anchor: start at 1

    UNION ALL

    SELECT n + 1            -- recursive: increment by 1
    FROM   number_series
    WHERE  n < 10           -- termination: stop at 10
)
SELECT n FROM number_series;
-- Returns: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
```

Practical application: generate a date range for a reporting calendar.

```sql
WITH RECURSIVE date_series AS (
    SELECT CAST('2024-01-01' AS DATE) AS dt

    UNION ALL

    SELECT dt + INTERVAL 1 DAY
    FROM   date_series
    WHERE  dt < '2024-01-31'
)
SELECT dt FROM date_series;
```

---

### Example 4 — Detecting Circular References (Cycle Guard)

In real data, manager relationships can accidentally form cycles (Employee A manages B who manages A). Add a depth guard:

```sql
WITH RECURSIVE safe_hierarchy AS (
    SELECT emp_id, name, manager_id, 0 AS depth
    FROM   employees
    WHERE  manager_id IS NULL

    UNION ALL

    SELECT e.emp_id, e.name, e.manager_id, sh.depth + 1
    FROM   employees      e
    JOIN   safe_hierarchy sh ON e.manager_id = sh.emp_id
    WHERE  sh.depth < 50      -- ← safety valve: stop at depth 50
)
SELECT * FROM safe_hierarchy;
```

> In PostgreSQL 14+, you can use `CYCLE emp_id SET is_cycle USING path` for built-in cycle detection.

---

## Recursive CTE vs Alternative Approaches

| Approach | Can handle variable depth? | Readable? | Performance |
|----------|--------------------------|-----------|---------| 
| **Recursive CTE** | ✅ Yes, any depth | ✅ Good | ✅ Good (single SQL statement) |
| **Multiple self-JOINs** | ❌ Fixed depth only | ❌ Poor | ❌ Poor at deep levels |
| **Stored procedure loop** | ✅ Yes | ⚠️ Medium | ⚠️ Overhead per iteration |
| **Nested Sets model** | ✅ Yes (pre-computed) | ❌ Complex setup | ✅ Very fast reads |
| **Application-level BFS/DFS** | ✅ Yes | ⚠️ Medium | ⚠️ N+1 query problem |

---

## Interview Tips

1. **Name all three parts.** When explaining recursive CTEs, always mention: anchor member, recursive member, and termination condition. This framework immediately signals competence.

2. **The termination condition is critical.** Say: *"If the recursive member always returns rows — for example due to circular references in data — the query loops until hitting the database's recursion limit and throws an error."* Then mention `cte_max_recursion_depth` (MySQL) or `MAXRECURSION` (SQL Server).

3. **`UNION ALL` not `UNION`.** The recursive member must use `UNION ALL`. Most databases do not even allow `UNION` (without `ALL`) in the recursive part. Know why: deduplication across an iterating result set is semantically problematic.

4. **Track depth and path as computed columns.** Adding a `level` counter and a `path` string in the SELECT list shows you know how to make the output useful — interviewers love this detail.

5. **Know the hierarchy use case cold.** The employee-manager tree is the canonical recursive CTE interview problem. Be able to write it from memory: anchor = `WHERE manager_id IS NULL`, recursive = `JOIN employees ON employee.manager_id = cte.emp_id`.

---

## ❓ Practice Questions

1. Write a recursive CTE that starts from the **CEO** (the employee with `manager_id IS NULL`) and outputs every employee in the organisation with their **level** (0 = CEO, 1 = direct reports, 2 = their reports, etc.).

2. Using a recursive CTE, find **all employees who directly or indirectly report to `emp_id = 1`** (the top manager). Include the depth level of each employee.

3. Write a recursive CTE to generate a **list of dates from `2024-06-01` to `2024-06-30`**, one row per day. Then join it to the `orders` table to count how many orders were placed on each date (include dates with zero orders).

4. Modify the hierarchy query to also display each employee's **department name** by joining the `departments` table. Show only employees in the **Engineering** department and their managers (even if the manager is in a different department).

5. A recursive CTE is running indefinitely on production. What are two likely causes, and how would you fix each? How do you set a recursion depth limit in MySQL vs SQL Server?
