# Important SQL Concepts for Placements

This file summarizes the core concepts you should understand, not just memorize.

## 1) Types of SQL Commands

- DDL: Structure changes (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`)
- DML: Data changes (`INSERT`, `UPDATE`, `DELETE`)
- DQL: Data retrieval (`SELECT`)
- DCL: Access control (`GRANT`, `REVOKE`)
- TCL: Transaction control (`COMMIT`, `ROLLBACK`, `SAVEPOINT`)

## 2) Keys in Databases

- Primary Key: Uniquely identifies each row; cannot be NULL.
- Foreign Key: Links one table to another table's primary key.
- Candidate Key: Possible columns that can become primary key.
- Composite Key: Key formed using multiple columns.
- Unique Key: Ensures uniqueness (NULL handling can vary by DB).

## 3) Normalization

Goal: Reduce redundancy and avoid anomalies.

- 1NF: Atomic values, no repeating groups.
- 2NF: In 1NF + no partial dependency on composite key.
- 3NF: In 2NF + no transitive dependency.
- BCNF: Stronger version of 3NF for certain dependency cases.

When to denormalize: For read-heavy analytics workloads where fewer joins improve performance.

## 4) Joins vs Union

- JOIN: Combines columns from multiple tables based on relation.
- UNION: Combines rows from multiple SELECT queries.
- UNION ALL: Keeps duplicates (faster than UNION).

## 5) Indexing

Indexes improve read speed but add cost to inserts/updates.

- B-Tree index: Most common for equality and range conditions.
- Composite index: Useful when query filters by multiple columns.
- Avoid over-indexing on frequently updated tables.
- Prefer indexing columns used in `WHERE`, `JOIN`, `ORDER BY`.

## 6) Transactions and ACID

- Atomicity: All operations succeed or none.
- Consistency: Database stays valid after transaction.
- Isolation: Concurrent transactions do not interfere incorrectly.
- Durability: Committed data survives crashes.

Isolation levels (common):

- Read Uncommitted
- Read Committed
- Repeatable Read
- Serializable

## 7) SQL Execution Order (Logical)

1. FROM / JOIN
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. ORDER BY
7. LIMIT

This explains why aliases in `SELECT` usually cannot be used in `WHERE`.

## 8) Subquery vs CTE

- Subquery: Inline query, good for simple nested logic.
- CTE: Named temporary result set, improves readability.
- Recursive CTE: Useful for hierarchical data (org chart, folders).

## 9) Window Functions

Used for analytics without collapsing rows.

Common ones:

- `ROW_NUMBER()`
- `RANK()` / `DENSE_RANK()`
- `LAG()` / `LEAD()`
- `SUM() OVER (...)`

Use cases:

- Top N per group
- Running totals
- Compare current row with previous row

## 10) Common SQL Interview Topics

- Difference between `WHERE` and `HAVING`
- `DELETE` vs `TRUNCATE` vs `DROP`
- Primary key vs unique key
- `INNER JOIN` vs `LEFT JOIN`
- Index advantages and trade-offs
- Finding nth highest salary
- Handling duplicates

## 11) Performance Basics

- Select only needed columns (avoid `SELECT *` in production).
- Filter early with indexed columns.
- Avoid functions on indexed columns in `WHERE` if possible.
- Use `EXPLAIN` / query plans to diagnose slow queries.
- Keep transactions short to reduce locking.

## 12) Placement Study Strategy

1. Practice one concept + two queries daily.
2. Write queries by hand before running them.
3. Solve patterns: joins, group by, subqueries, windows.
4. Revise mistakes in a separate notes file.
5. Time yourself on 5-query mini tests.
