# Summary: SQL UNION and UNION ALL Clause

## Core idea

`UNION` combines the results of two or more `SELECT` queries into one result set.
By default, `UNION` removes duplicate rows.

If you want to keep duplicate rows, use `UNION ALL`.

## Rules for using UNION

- Each `SELECT` must return the same number of columns.
- Columns must be in the same order.
- Corresponding columns should have compatible data types.
- `UNION` removes duplicates, while `UNION ALL` keeps them.

## Main syntax

```sql
SELECT column_name(s)
FROM table1
UNION
SELECT column_name(s)
FROM table2;
```

```sql
SELECT column_name(s)
FROM table1
UNION ALL
SELECT column_name(s)
FROM table2;
```

## Example setup

```sql
CREATE TABLE Students (
  ROLL_NO INT,
  NAME VARCHAR(50)
);

INSERT INTO Students (ROLL_NO, NAME) VALUES
(1, 'Aman'),
(2, 'Bina'),
(3, 'Chetan'),
(4, 'Diya'),
(5, 'Eshan');

CREATE TABLE Student_Details (
  ROLL_NO INT,
  BRANCH VARCHAR(50)
);

INSERT INTO Student_Details (ROLL_NO, BRANCH) VALUES
(1, 'CSE'),
(2, 'ECE'),
(3, 'ME'),
(6, 'CE'),
(7, 'IT');
```

## Example 1: UNION returns distinct roll numbers

```sql
SELECT ROLL_NO
FROM Students
UNION
SELECT ROLL_NO
FROM Student_Details;
```

Sample output:

```text
ROLL_NO
1
2
3
4
5
6
7
```

Explanation:
`UNION` removes duplicates, so roll numbers present in both tables (1, 2, 3) appear only once.

## Example 2: UNION ALL keeps duplicates

```sql
SELECT ROLL_NO
FROM Students
UNION ALL
SELECT ROLL_NO
FROM Student_Details;
```

Sample output:

```text
ROLL_NO
1
2
3
4
5
1
2
3
6
7
```

Explanation:
`UNION ALL` does not remove duplicates, so common roll numbers are shown again.

## Example 3: UNION ALL with conditions and sorting

```sql
SELECT ROLL_NO, NAME
FROM Students
WHERE ROLL_NO > 3
UNION ALL
SELECT ROLL_NO, BRANCH
FROM Student_Details
WHERE ROLL_NO < 3
ORDER BY 1;
```

Sample output:

```text
ROLL_NO | VALUE
1       | CSE
2       | ECE
4       | Diya
5       | Eshan
```

Explanation:
The first query returns students with `ROLL_NO > 3`.
The second query returns branches with `ROLL_NO < 3`.
`UNION ALL` combines both sets without removing duplicates.
`ORDER BY 1` sorts the final result by `ROLL_NO` (first selected column).

## Key points

- Use `UNION` when you need distinct combined results.
- Use `UNION ALL` when duplicate rows are important.
- Keep selected columns aligned across all queries.
- Apply `ORDER BY` at the end to sort the final merged output.
