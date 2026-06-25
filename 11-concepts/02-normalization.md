# Database Normalization — Eliminating Redundancy Step by Step

> **Interview Priority**: 🔴 Must Know

## What Is It?

Normalization is the process of organizing a relational database to **reduce data redundancy** and **prevent data anomalies**. It works by decomposing tables into smaller, well-structured tables linked by keys.

The three anomalies normalization prevents:
- **Insert anomaly**: Can't add partial data without unrelated data
- **Update anomaly**: Changing one fact requires updating multiple rows
- **Delete anomaly**: Deleting one thing accidentally removes unrelated data

---

## The Progression: Start Denormalized → Normalize Step by Step

### ❌ Starting Point: Badly Denormalized Table

```
employee_info
┌────────┬──────────┬─────────┬──────────────┬───────────┬──────────────────┐
│ emp_id │ emp_name │ dept_id │  dept_name   │ dept_head │    projects      │
├────────┼──────────┼─────────┼──────────────┼───────────┼──────────────────┤
│   1    │  Aman    │   10    │ Engineering  │   Ravi    │ Alpha, Beta      │
│   2    │  Priya   │   20    │     HR       │   Zara    │ Gamma            │
│   3    │  Dev     │   10    │ Engineering  │   Ravi    │ Alpha, Delta     │
└────────┴──────────┴─────────┴──────────────┴───────────┴──────────────────┘
```

Problems:
- `dept_name` and `dept_head` repeat for every employee in the same dept → update anomaly
- `projects` column holds multiple values → violates atomicity
- Deleting the last HR employee would lose HR dept info → delete anomaly

---

## 1NF — First Normal Form

**Rule**: Each column must hold **atomic (indivisible) values**. No repeating groups or arrays.

```sql
-- ❌ Before 1NF: projects = 'Alpha, Beta'
-- ✅ After 1NF: one row per project

CREATE TABLE employee_projects (
  emp_id      INT,
  emp_name    VARCHAR(100),
  dept_id     INT,
  dept_name   VARCHAR(100),
  dept_head   VARCHAR(100),
  project     VARCHAR(100)   -- now atomic
);
```

```
┌────────┬──────────┬─────────┬──────────────┬───────────┬─────────┐
│ emp_id │ emp_name │ dept_id │  dept_name   │ dept_head │ project │
├────────┼──────────┼─────────┼──────────────┼───────────┼─────────┤
│   1    │  Aman    │   10    │ Engineering  │   Ravi    │  Alpha  │
│   1    │  Aman    │   10    │ Engineering  │   Ravi    │  Beta   │
│   2    │  Priya   │   20    │     HR       │   Zara    │  Gamma  │
│   3    │  Dev     │   10    │ Engineering  │   Ravi    │  Alpha  │
│   3    │  Dev     │   10    │ Engineering  │   Ravi    │  Delta  │
└────────┴──────────┴─────────┴──────────────┴───────────┴─────────┘
Composite PK: (emp_id, project)
```

Still has issues — `dept_name` and `dept_head` only depend on `dept_id`, not the full composite PK.

---

## 2NF — Second Normal Form

**Rule**: Must be in 1NF + **no partial dependency** (every non-key column must depend on the WHOLE primary key, not just part of it). Only relevant when there's a composite primary key.

Split out the partial dependency (`dept_name`, `dept_head` depend only on `dept_id`, not on `project`):

```sql
-- Table 1: employees (depends on emp_id only)
CREATE TABLE employees (
  emp_id    INT PRIMARY KEY,
  emp_name  VARCHAR(100),
  dept_id   INT
);

-- Table 2: departments (partial dependency extracted)
CREATE TABLE departments (
  dept_id   INT PRIMARY KEY,
  dept_name VARCHAR(100),
  dept_head VARCHAR(100)
);

-- Table 3: emp_projects (bridge — depends on full composite PK)
CREATE TABLE emp_projects (
  emp_id   INT,
  project  VARCHAR(100),
  PRIMARY KEY (emp_id, project)
);
```

Now `dept_name` is stored once per department. Update one row → consistent everywhere.

---

## 3NF — Third Normal Form

**Rule**: Must be in 2NF + **no transitive dependency** (non-key column must not depend on another non-key column).

Problem in our `departments` table:

```
dept_id → dept_name → dept_head
```

`dept_head` depends on `dept_name`, not directly on `dept_id`. That's a transitive dependency.

```sql
-- Split to remove transitive dependency
CREATE TABLE departments (
  dept_id   INT PRIMARY KEY,
  dept_name VARCHAR(100),
  head_id   INT  -- FK to department_heads
);

CREATE TABLE department_heads (
  head_id   INT PRIMARY KEY,
  head_name VARCHAR(100)
);
```

Now every non-key column in every table depends **only** on the primary key — nothing else.

---

## BCNF — Boyce-Codd Normal Form

**Rule**: Stricter than 3NF. For every functional dependency `X → Y`, X must be a **superkey** (candidate key or primary key).

Most tables in 3NF are also in BCNF. A violation occurs only in rare multi-candidate-key situations. For placements, understanding 3NF is usually sufficient — just know BCNF exists and is stronger.

---

## Summary Table

| Normal Form | Rule | Fixes |
|---|---|---|
| **1NF** | Atomic values, no repeating groups | Arrays, comma-separated values |
| **2NF** | No partial dependency (on composite PK) | Columns depending on part of PK |
| **3NF** | No transitive dependency | Column A → Column B → Column C chains |
| **BCNF** | Every determinant is a superkey | Edge cases in 3NF |

---

## Denormalization: When to Break the Rules

Sometimes you **intentionally** add redundancy for performance:

- **Analytics / Data warehousing**: Fewer joins = faster aggregations (star schema, fact tables)
- **Read-heavy systems**: Pre-join common queries into wide tables
- **Caching summaries**: Store pre-computed `total_orders` on customer row

```sql
-- Denormalized: employees table stores dept_name directly
-- Avoids the JOIN to departments on every query
SELECT emp_id, emp_name, dept_name   -- no JOIN needed
FROM employees_denormalized;
```

**Trade-off**: Faster reads, but update anomalies return. Acceptable in read-only/analytics contexts.

---

## Key Concepts

- Each normal form builds on the previous one
- Normalization is driven by **functional dependencies** (A → B means knowing A tells you B)
- The goal is: one fact, one place
- Most OLTP databases aim for 3NF
- Data warehouses (OLAP) are often intentionally denormalized

---

## Interview Tips

1. **Always explain *why*** you normalize — "to remove redundancy and prevent update/delete/insert anomalies"
2. **1NF violation example**: storing `"Alpha, Beta"` in one column — interviewers love this
3. **Transitive dependency** is the most common 3NF question — be able to give a concrete example
4. **Denormalization** is a valid answer when they ask "would you always normalize?" — shows maturity
5. Know the difference between **OLTP** (normalized, write-heavy) and **OLAP** (denormalized, read-heavy)

---

## ❓ Practice Questions

1. The `employees` table has columns: `emp_id`, `emp_name`, `dept_id`, `dept_name`, `dept_location`, `manager_name`. Which normal form is violated and why? How would you fix it?

2. A table `student_courses` has columns `(student_id, course_id, student_name, course_name, instructor)`. The PK is `(student_id, course_id)`. Identify all normal form violations and normalize to 3NF.

3. What is a transitive dependency? Give an example using the `departments` table (dept_id, dept_name, dept_head_name, dept_head_phone).

4. When would you denormalize the `orders` table to include `customer_name` directly instead of joining to `customers`? What are the risks?

5. Explain the difference between 2NF and 3NF with concrete examples from a school database (students, courses, grades).
