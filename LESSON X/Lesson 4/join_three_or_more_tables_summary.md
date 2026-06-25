# Summary: Joining Three or More Tables in SQL

## Core idea

A SQL `JOIN` combines rows from multiple tables using related columns.
When data is split across several tables, multi-table joins help fetch complete and meaningful results in one query.

## Why join multiple tables

- Combine data from separate tables into one result set.
- Retrieve related information using foreign key relationships.
- Run complex queries that require multiple data sources.

## How to join 3 or more tables

To join `n` tables, you usually need at least `n - 1` join conditions.

Two common methods:

1. Chained `JOIN` statements (recommended)
2. Comma-separated tables with `WHERE` conditions (older style)

## Example setup

```sql
CREATE TABLE student (
  s_id INT PRIMARY KEY,
  s_name VARCHAR(50)
);

CREATE TABLE marks (
  s_id INT,
  score INT,
  status VARCHAR(20),
  school_id INT
);

CREATE TABLE details (
  school_id INT,
  address_city VARCHAR(50),
  email_id VARCHAR(100),
  accomplishments VARCHAR(100)
);

INSERT INTO student (s_id, s_name) VALUES
(1, 'Aarav'),
(2, 'Meera'),
(3, 'Rohan'),
(4, 'Sara');

INSERT INTO marks (s_id, score, status, school_id) VALUES
(1, 89, 'Pass', 101),
(2, 92, 'Pass', 102),
(3, 55, 'Pass', 103);

INSERT INTO details (school_id, address_city, email_id, accomplishments) VALUES
(101, 'Delhi', 'aarav@example.com', 'Debate Winner'),
(102, 'Pune', 'meera@example.com', 'Science Fair'),
(104, 'Mumbai', 'unknown@example.com', 'Sports Captain');
```

In this setup:

- `student` is parent of `marks` via `s_id`.
- `marks` is parent of `details` via `school_id`.

## 1) Using SQL JOIN (recommended)

```sql
SELECT s.s_name, m.score, m.status, d.address_city, d.email_id, d.accomplishments
FROM student s
INNER JOIN marks m ON s.s_id = m.s_id
INNER JOIN details d ON m.school_id = d.school_id;
```

Sample output:

```text
s_name | score | status | address_city | email_id           | accomplishments
Aarav  | 89    | Pass   | Delhi        | aarav@example.com  | Debate Winner
Meera  | 92    | Pass   | Pune         | meera@example.com  | Science Fair
```

Explanation:

- First `INNER JOIN` combines `student` with `marks` using `s_id`.
- Second `INNER JOIN` combines that result with `details` using `school_id`.
- Only rows matching across all tables are returned.

## 2) Using parent-child relationship with WHERE

```sql
CREATE TABLE student (
    s_id INT PRIMARY KEY,
    s_name VARCHAR(50)
);

CREATE TABLE marks (
    m_id INT PRIMARY KEY,
    s_id INT,
    school_id INT,
    score INT,
    status VARCHAR(20),
    FOREIGN KEY (s_id) REFERENCES student(s_id)
);

CREATE TABLE details (
    d_id INT PRIMARY KEY,
    school_id INT,
    address_city VARCHAR(50),
    email_id VARCHAR(100),
    accomplishments VARCHAR(100),
    FOREIGN KEY (school_id) REFERENCES marks(school_id)
);
```

```sql
SELECT s.s_name, m.score, m.status, d.address_city, d.email_id, d.accomplishments
FROM student s, marks m, details d
WHERE s.s_id = m.s_id
  AND m.school_id = d.school_id;
```

Explanation:

- This is older implicit join syntax.
- It uses parent-child key relationships in the `WHERE` clause.
- Result is equivalent to the inner join version above.

## Advanced techniques

### LEFT JOIN to keep unmatched rows from first table

```sql
SELECT s.s_name, m.score, m.status, d.address_city, d.email_id, d.accomplishments
FROM student s
LEFT JOIN marks m ON s.s_id = m.s_id
LEFT JOIN details d ON m.school_id = d.school_id;
```

Explanation:

- Returns all students, even if marks/details are missing.
- Unmatched columns from joined tables appear as `NULL`.

### FULL OUTER JOIN to keep all rows from all tables

```sql
SELECT s.s_name, m.score, m.status, d.address_city, d.email_id, d.accomplishments
FROM student s
FULL OUTER JOIN marks m ON s.s_id = m.s_id
FULL OUTER JOIN details d ON m.school_id = d.school_id;
```

Explanation:

- Returns every row from all tables.
- Matching rows are combined.
- Non-matching sides show `NULL` values.

## Key points

- For `n` tables, minimum join conditions are usually `n - 1`.
- Prefer explicit `JOIN ... ON ...` syntax for readability and maintenance.
- Use `LEFT JOIN` when you must keep all rows from the first table.
- Use `FULL OUTER JOIN` when you must keep all rows from every table.

> LEFT JOIN = LEFT OUTER JOIN.  
> RIGHT JOIN = RIGHT OUTER JOIN.  
> FULL JOIN = FULL OUTER JOIN.
