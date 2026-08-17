## COALESCE VS IFNULL
### IFNULL(expression, replacement_value)
IFNULL() takes 2 arguments:
```IFNULL(a, 0)```.  
COALESCE() can take multiple arguments and returns the first non-NULL value:
```COALESCE(a, b, c, 0)```

# Surf-QL — SQL Placement Preparation Guide

A structured, interview-ready SQL study repository. Every topic file includes explanations, examples using a **shared dataset**, interview tips, and practice questions.


| S.No | Topic | Completion Date | Revision Date | Fully |
|------|-------|----------------|---------------|-------|
| 1    |  BASICS      |    26 JUNE            |             | ☐     |
| 2    |  filtering and sorting     |      27 JUNE          |             | ☐     |
| 3    |    GROUPING AND AGGREGATION  |     28 JUNE         |             | ☐     |
| 4    |   JOINS |     28 JUNE         |             | ☐     |


---

## Shared Dataset

All examples across this repo use the same set of tables defined in [`dataset.sql`](./dataset.sql).

**Tables**: `employees`, `departments`, `customers`, `orders`, `products`, `performance`

Run `dataset.sql` once to set up the data for practice.

---

## Study Roadmap

Work through modules in order. Each folder builds on the previous.

---

### Module 1 — Basics
> DDL fundamentals, reading and writing data. Start here.

| # | File | Topic |
|---|---|---|
| 1 | [01-create-database.md](./01-basics/01-create-database.md) | CREATE DATABASE, USE, DROP DATABASE |
| 2 | [02-create-tables.md](./01-basics/02-create-tables.md) | CREATE TABLE, data types, inline constraints |
| 3 | [03-select-clause.md](./01-basics/03-select-clause.md) | SELECT, aliases, expressions, DISTINCT |
| 4 | [04-where-clause.md](./01-basics/04-where-clause.md) | WHERE, AND/OR/NOT, NULL handling |
| 5 | [05-insert-into.md](./01-basics/05-insert-into.md) | INSERT INTO, INSERT SELECT, multiple rows |
| 6 | [06-update-statement.md](./01-basics/06-update-statement.md) | UPDATE SET WHERE, UPDATE with subquery |
| 7 | [07-delete-statement.md](./01-basics/07-delete-statement.md) | DELETE FROM, DELETE with subquery |
| 8 | [08-drop-truncate.md](./01-basics/08-drop-truncate.md) | DROP vs TRUNCATE vs DELETE |
| 9 | [09-operators.md](./01-basics/09-operators.md) | IN, BETWEEN, LIKE, IS NULL, comparison ops |
| 10 | [10-constraints.md](./01-basics/10-constraints.md) | PK, FK, UNIQUE, CHECK, NOT NULL, DEFAULT |

---

### Module 2 — Filtering & Sorting
> How to control which rows you see and in what order.

| # | File | Topic |
|---|---|---|
| 1 | [01-order-by.md](./02-filtering-and-sorting/01-order-by.md) | ORDER BY ASC/DESC, multi-column, NULLS FIRST/LAST |
| 2 | [02-limit-offset.md](./02-filtering-and-sorting/02-limit-offset.md) | LIMIT, OFFSET, pagination, dialect differences |
| 3 | [03-like-wildcard.md](./02-filtering-and-sorting/03-like-wildcard.md) | LIKE, %, _, ILIKE, escape characters |
| 4 | [04-in-between-null.md](./02-filtering-and-sorting/04-in-between-null.md) | IN, NOT IN NULL trap, BETWEEN, IS NULL |
| 5 | [05-case-statement.md](./02-filtering-and-sorting/05-case-statement.md) | Simple CASE, Searched CASE, conditional aggregation |

---

### Module 3 — Grouping & Aggregation
> Summarizing data — the most common interview topic after JOINs.

| # | File | Topic |
|---|---|---|
| 1 | [01-group-by.md](./03-grouping-and-aggregation/01-group-by.md) | GROUP BY, ROLLUP, CUBE, GROUPING SETS |
| 2 | [02-having-clause.md](./03-grouping-and-aggregation/02-having-clause.md) | HAVING vs WHERE — the critical difference |
| 3 | [03-aggregate-functions.md](./03-grouping-and-aggregation/03-aggregate-functions.md) | COUNT, SUM, AVG, MIN, MAX, NULL behavior |
| 4 | [04-distinct-clause.md](./03-grouping-and-aggregation/04-distinct-clause.md) | DISTINCT, COUNT(DISTINCT), DISTINCT vs GROUP BY |

---

### Module 4 — Joins
> Combining tables — the single most important SQL skill for interviews.

| # | File | Topic |
|---|---|---|
| 1 | [01-inner-join.md](./04-joins/01-inner-join.md) | INNER JOIN — intersection of two tables |
| 2 | [02-left-right-join.md](./04-joins/02-left-right-join.md) | LEFT/RIGHT JOIN — ON vs WHERE trap  |
| 3 | [03-full-outer-join.md](./04-joins/03-full-outer-join.md) | FULL OUTER JOIN, MySQL workaround |
| 4 | [04-cross-self-join.md](./04-joins/04-cross-self-join.md) | CROSS JOIN, SELF JOIN (employee-manager) |
| 5 | [05-union-intersect-except.md](./04-joins/05-union-intersect-except.md) | UNION, UNION ALL, INTERSECT, EXCEPT |
| 6 | [06-advanced-join-patterns.md](./04-joins/06-advanced-join-patterns.md) | Semi/Anti join, LATERAL, non-equi, fan-out |

---

### Module 5 — Subqueries
> Nested queries — from basics to the correlated subquery trap.

| # | File | Topic |
|---|---|---|
| 1 | [01-subqueries-basics.md](./05-subqueries/01-subqueries-basics.md) | Scalar, row, table subqueries — WHERE/FROM/HAVING |
| 2 | [02-correlated-subqueries.md](./05-subqueries/02-correlated-subqueries.md) | Correlated subqueries — why they're slow + rewrites |
| 3 | [03-exists-any-all.md](./05-subqueries/03-exists-any-all.md) | EXISTS, NOT EXISTS, ANY, ALL, IN vs EXISTS |

---

### Module 6 — CTEs & Window Functions
> The two most powerful SQL features for analytics and complex problems.

| # | File | Topic |
|---|---|---|
| 1 | [01-cte-guide.md](./06-cte-and-window-functions/01-cte-guide.md) | WITH clause, multiple CTEs, CTE with DML |
| 2 | [02-recursive-cte.md](./06-cte-and-window-functions/02-recursive-cte.md) | WITH RECURSIVE — hierarchy traversal |
| 3 | [03-window-functions.md](./06-cte-and-window-functions/03-window-functions.md) | ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, SUM OVER |
| 4 | [04-frame-clause.md](./06-cte-and-window-functions/04-frame-clause.md) | ROWS vs RANGE, frame boundaries |

---

### Module 7 — Schema & DDL
> Views, indexes, stored procedures — asked in SDE and analyst rounds.

| # | File | Topic |
|---|---|---|
| 1 | [01-alter-table.md](./07-schema-and-ddl/01-alter-table.md) | ALTER TABLE — add, drop, rename, modify columns |
| 2 | [02-views.md](./07-schema-and-ddl/02-views.md) | Views, materialized views, updatable views |
| 3 | [03-indexes.md](./07-schema-and-ddl/03-indexes.md) | B-Tree indexes, composite, covering, when NOT used |
| 4 | [04-stored-procedures-triggers.md](./07-schema-and-ddl/04-stored-procedures-triggers.md) | Stored procedures, triggers, UDFs |

---

### Module 8 — Transactions & ACID
> Database theory — asked in nearly every backend/SDE interview.

| # | File | Topic |
|---|---|---|
| 1 | [01-transactions.md](./08-transactions-and-acid/01-transactions.md) | BEGIN, COMMIT, ROLLBACK, SAVEPOINT |
| 2 | [02-acid-and-isolation.md](./08-transactions-and-acid/02-acid-and-isolation.md) | ACID properties, isolation levels, dirty reads |

---

### Module 9 — String & Date Functions
> Data cleaning and time-series queries — common in analytics interviews.

| # | File | Topic |
|---|---|---|
| 1 | [01-string-functions.md](./09-string-and-date-functions/01-string-functions.md) | CONCAT, TRIM, SUBSTR, REPLACE, COALESCE, NULLIF |
| 2 | [02-date-functions.md](./09-string-and-date-functions/02-date-functions.md) | NOW, DATE_ADD, DATEDIFF, EXTRACT, DATE_FORMAT |

---

### Module 10 — Interview Patterns
> Reusable patterns that solve 90% of SQL interview questions.

| # | File | Topic |
|---|---|---|
| 1 | [01-top-sql-patterns.md](./10-interview-patterns/01-top-sql-patterns.md) | 12 core patterns: aggregation, anti-join, running total... |
| 2 | [02-nth-highest-salary.md](./10-interview-patterns/02-nth-highest-salary.md) |  The #1 most asked question — 5 approaches |
| 3 | [03-rapid-fire-differences.md](./10-interview-patterns/03-rapid-fire-differences.md) | 15 classic comparisons: WHERE vs HAVING, RANK vs DENSE_RANK... |

---

### Module 11 — Core Concepts
> Theory that underpins everything — essential for DBMS rounds.

| # | File | Topic |
|---|---|---|
| 1 | [01-sql-execution-order.md](./11-concepts/01-sql-execution-order.md) | FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY |
| 2 | [02-normalization.md](./11-concepts/02-normalization.md) | 1NF, 2NF, 3NF, BCNF — with step-by-step example |
| 3 | [03-performance-basics.md](./11-concepts/03-performance-basics.md) | 11 query optimization tips with examples |
| 4 | [04-sql-commands-reference.md](./11-concepts/04-sql-commands-reference.md) |  Complete cheatsheet — DDL, DML, TCL, DCL, functions |

---

##  Interview Priority Guide

| Priority | Modules |
|---|---|
|  **Must Know** | 1, 2, 3, 4 (joins), 6 (window functions), 10 |
|  **Important** | 5 (subqueries), 7 (views/indexes), 8 (ACID) |
|  **Good to Know** | 9 (string/date), 11 (theory) |

---

##  Resources

- [Beyond LeetCode SQL](https://github.com/shawlu95/Beyond-LeetCode-SQL) — advanced problem patterns
- [LeetCode SQL 50](https://leetcode.com/studyplan/top-sql-50/) — most common interview questions

---

##  Study Strategy

1. **Do one module per day** — don't rush
2. **Write queries by hand** before checking answers
3. **Say your reasoning out loud** — interviews are verbal
4. **Use the practice questions** at the end of each file
5. **Review `03-rapid-fire-differences.md`** the night before any interview
