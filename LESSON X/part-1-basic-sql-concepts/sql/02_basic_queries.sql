-- Part 1 query practice script
USE surfql_part1;

-- SELECT + FROM
SELECT * FROM students;
SELECT student_name, city FROM students;
SELECT DISTINCT city FROM students;

-- WHERE
SELECT * FROM students WHERE city = 'Delhi';
SELECT * FROM students WHERE age > 20;

-- Operators
SELECT *
FROM students
WHERE city = 'Delhi' AND age >= 20;

SELECT *
FROM students
WHERE city = 'Delhi' OR city = 'Mumbai';

SELECT *
FROM students
WHERE NOT city = 'Pune';

SELECT *
FROM students
WHERE age BETWEEN 19 AND 21;

SELECT *
FROM students
WHERE city IN ('Delhi', 'Pune');

SELECT *
FROM students
WHERE student_name LIKE 'A%';

-- INSERT INTO
INSERT INTO students (student_id, student_name, age, city, dept_id)
VALUES (6, 'Neha', 23, 'Hyderabad', 20);

SELECT * FROM students WHERE student_id = 6;

-- DELETE
DELETE FROM students WHERE student_id = 6;
SELECT * FROM students WHERE student_id = 6;
