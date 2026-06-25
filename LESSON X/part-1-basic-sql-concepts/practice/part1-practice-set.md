# Part 1 Practice Set (Basic SQL Concepts)

Use the sample tables from `sql/01_schema_and_seed.sql`.
Try solving these without seeing answers first.

## A) Creating Database / Tables

1. Create a database named `college_lab`.
2. Create a table `courses` with `course_id` as primary key and `course_name` as unique.
3. Add a foreign key in `students` that references `courses(course_id)`.

## B) SELECT and FROM

1. Show all rows from `students`.
2. Show only `student_name` and `city`.
3. Show distinct cities from `students`.
4. Show `student_name` as `name` using alias.

## C) WHERE and Operators

1. Find students with `age > 20`.
2. Find students from `Delhi` or `Pune`.
3. Find students not from `Mumbai`.
4. Find students with age between 19 and 21.
5. Find students whose names start with `A`.
6. Find students in departments 10 or 30 and age >= 20.

## D) INSERT INTO

1. Insert one new student row.
2. Insert three student rows in one query.
3. Insert a row with a duplicate `student_id` and observe the error.

## E) DELETE

1. Delete one student using `student_id`.
2. Delete all students from a specific city.
3. Delete all rows from `students` using `DELETE` (do this only in practice DB).

## F) TRUNCATE and DROP

1. Refill data and run `TRUNCATE TABLE students`.
2. Recreate table and run `DROP TABLE students`.
3. Explain in your own words when to use each command.
