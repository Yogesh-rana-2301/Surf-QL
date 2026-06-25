# Summary: SQL Joins (INNER, LEFT, RIGHT, FULL, NATURAL)

## Core idea

SQL joins combine data from two or more tables using related columns.
They help retrieve connected information and produce meaningful result sets.

## Why joins are important

- Retrieve related data stored in separate tables.
- Match records using common columns.
- Improve analysis by combining context from multiple tables.
- Build richer outputs than single-table queries.

## Example tables

```sql
CREATE TABLE Student (
  ROLL_NO INT,
  NAME VARCHAR(50),
  AGE INT
);

INSERT INTO Student (ROLL_NO, NAME, AGE) VALUES
(1, 'Ryan Miller', 18),
(2, 'James Wilson', 18),
(3, 'Lucas Brown', 20),
(4, 'Daniel Smith', 18);

CREATE TABLE StudentCourse (
  COURSE_ID INT,
  ROLL_NO INT
);

INSERT INTO StudentCourse (COURSE_ID, ROLL_NO) VALUES
(101, 1),
(102, 2),
(103, 2),
(104, 5);
```

In this setup:

- `ROLL_NO = 1, 2` appear in both tables.
- `ROLL_NO = 3, 4` exist only in `Student`.
- `ROLL_NO = 5` exists only in `StudentCourse`.

## 1) INNER JOIN

`INNER JOIN` returns only rows that match in both tables.

Syntax:

```sql
SELECT table1.column1, table2.column2
FROM table1
INNER JOIN table2
  ON table1.matching_column = table2.matching_column;
```

Note: `JOIN` and `INNER JOIN` are equivalent.

Example:

```sql
SELECT StudentCourse.COURSE_ID, Student.NAME, Student.AGE
FROM Student
INNER JOIN StudentCourse
  ON Student.ROLL_NO = StudentCourse.ROLL_NO;
```

Sample output:

```text
COURSE_ID | NAME         | AGE
101       | Ryan Miller  | 18
102       | James Wilson | 18
103       | James Wilson | 18
```

## 2) LEFT JOIN

`LEFT JOIN` returns all rows from the left table and matched rows from the right table.
If no match exists, right-side columns become `NULL`.

Syntax:

```sql
SELECT table1.column1, table2.column2
FROM table1
LEFT JOIN table2
  ON table1.matching_column = table2.matching_column;
```

Example:

```sql
SELECT Student.NAME, StudentCourse.COURSE_ID
FROM Student
LEFT JOIN StudentCourse
  ON StudentCourse.ROLL_NO = Student.ROLL_NO;
```

Sample output:

```text
NAME         | COURSE_ID
Ryan Miller  | 101
James Wilson | 102
James Wilson | 103
Lucas Brown  | NULL
Daniel Smith | NULL
```

## 3) RIGHT JOIN

`RIGHT JOIN` returns all rows from the right table and matched rows from the left table.
If no match exists, left-side columns become `NULL`.

Syntax:

```sql
SELECT table1.column1, table2.column2
FROM table1
RIGHT JOIN table2
  ON table1.matching_column = table2.matching_column;
```

Example:

```sql
SELECT Student.NAME, StudentCourse.COURSE_ID
FROM Student
RIGHT JOIN StudentCourse
  ON StudentCourse.ROLL_NO = Student.ROLL_NO;
```

Sample output:

```text
NAME         | COURSE_ID
Ryan Miller  | 101
James Wilson | 102
James Wilson | 103
NULL         | 104
```

## 4) FULL JOIN

`FULL JOIN` combines `LEFT JOIN` and `RIGHT JOIN` behavior.
It returns all rows from both tables, matched where possible, and `NULL` for non-matching sides.

Syntax:

```sql
SELECT table1.column1, table2.column2
FROM table1
FULL JOIN table2
  ON table1.matching_column = table2.matching_column;
```

Example:

```sql
SELECT Student.NAME, StudentCourse.COURSE_ID
FROM Student
FULL JOIN StudentCourse
  ON StudentCourse.ROLL_NO = Student.ROLL_NO;
```

Sample output:

```text
NAME         | COURSE_ID
Ryan Miller  | 101
James Wilson | 102
James Wilson | 103
Lucas Brown  | NULL
Daniel Smith | NULL
NULL         | 104
```

## 5) NATURAL JOIN

`NATURAL JOIN` is a type of join that automatically matches columns with the same name and compatible data type in both tables.
The common column appears once in the output.

Syntax:

```sql
SELECT column_list
FROM table1
NATURAL JOIN table2;
```

Example:

```sql
CREATE TABLE Employee (
  Emp_ID INT,
  Emp_Name VARCHAR(50),
  Dept_ID INT
);

CREATE TABLE Department (
  Dept_ID INT,
  Dept_Name VARCHAR(50)
);

SELECT Emp_Name, Dept_Name
FROM Employee
NATURAL JOIN Department;
```

## Key points

- `INNER JOIN` returns only matching rows.
- `LEFT JOIN` keeps all rows from the left table.
- `RIGHT JOIN` keeps all rows from the right table.
- `FULL JOIN` keeps all rows from both tables.
- `NATURAL JOIN` auto-matches same-named columns, so use it carefully to avoid unintended matches.
