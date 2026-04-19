# Summary: SQL Cartesian (Cross) Join and Self Join

## Core idea

`CARTESIAN JOIN` (also called `CROSS JOIN`) and `SELF JOIN` are different join techniques in SQL.

- `CROSS JOIN` pairs every row of one table with every row of another table.
- `SELF JOIN` joins a table with itself to compare rows inside the same table.

## 1) CARTESIAN JOIN (CROSS JOIN)

### What it does

A `CROSS JOIN` returns the Cartesian product of two tables.
If table A has `m` rows and table B has `n` rows, result size is `m * n` rows.

### Syntax

```sql
SELECT table1.column1, table1.column2, table2.column1, ...
FROM table1
CROSS JOIN table2;
```

Note:

- Without filtering, it returns all combinations.
- If you add a `WHERE` condition that matches related rows, the final result behaves like an inner-style filtered set.

### Example setup

```sql
CREATE TABLE Student (
  ROLL_NO INT,
  NAME VARCHAR(50),
  ADDRESS VARCHAR(100),
  PHONE VARCHAR(15),
  AGE INT
);

INSERT INTO Student (ROLL_NO, NAME, ADDRESS, PHONE, AGE) VALUES
(1, 'Ryan Miller', 'New York', 'XXXXXXXXXX', 18),
(2, 'James Wilson', 'Los Angeles', 'XXXXXXXXXX', 18),
(3, 'Lucas Brown', 'Chicago', 'XXXXXXXXXX', 20),
(4, 'Daniel Smith', 'San Francisco', 'XXXXXXXXXX', 18);

CREATE TABLE StudentCourse (
  COURSE_ID INT,
  ROLL_NO INT
);

INSERT INTO StudentCourse (COURSE_ID, ROLL_NO) VALUES
(1, 1),
(2, 2),
(2, 3),
(3, 4);
```

### Example query

```sql
SELECT Student.NAME, Student.AGE, StudentCourse.COURSE_ID
FROM Student
CROSS JOIN StudentCourse;
```

Sample output:

```text
NAME          | AGE | COURSE_ID
Ryan Miller   | 18  | 1
Ryan Miller   | 18  | 2
Ryan Miller   | 18  | 2
Ryan Miller   | 18  | 3
James Wilson  | 18  | 1
James Wilson  | 18  | 2
James Wilson  | 18  | 2
James Wilson  | 18  | 3
Lucas Brown   | 20  | 1
Lucas Brown   | 20  | 2
Lucas Brown   | 20  | 2
Lucas Brown   | 20  | 3
Daniel Smith  | 18  | 1
Daniel Smith  | 18  | 2
Daniel Smith  | 18  | 2
Daniel Smith  | 18  | 3
```

Explanation:
There are 4 rows in `Student` and 4 rows in `StudentCourse`, so `CROSS JOIN` returns `4 * 4 = 16` rows.

## 2) SELF JOIN

### What it does

A `SELF JOIN` joins a table with itself.
It is useful for comparing rows in the same table.

### Syntax

```sql
SELECT a.column1, b.column2
FROM table_name a, table_name b
WHERE some_condition;
```

### Example query

```sql
SELECT a.ROLL_NO, b.NAME
FROM Student a, Student b
WHERE a.ROLL_NO < b.ROLL_NO;
```

Sample output:

```text
ROLL_NO | NAME
1       | James Wilson
1       | Lucas Brown
2       | Lucas Brown
1       | Daniel Smith
2       | Daniel Smith
3       | Daniel Smith
```

Explanation:
`Student` is used twice with aliases `a` and `b`.
The condition `a.ROLL_NO < b.ROLL_NO` pairs each student with students having a higher roll number.

## Key differences

- `CROSS JOIN` combines every row from two tables.
- `SELF JOIN` compares rows within the same table.
- `CROSS JOIN` can create very large result sets.
- `SELF JOIN` is commonly used for hierarchy, pairing, and row comparison problems.

## Key points

- Use `CROSS JOIN` when you need all combinations.
- Use `SELF JOIN` when you need relationships inside one table.
- Always check expected row count to avoid accidentally huge outputs.
