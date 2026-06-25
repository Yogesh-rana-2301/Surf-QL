-- Part 1 setup script (MySQL friendly)

-- 1) Create and switch database
CREATE DATABASE IF NOT EXISTS surfql_part1;
USE surfql_part1;

-- 2) Clean existing objects for repeatable runs
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS departments;

-- 3) Create tables
CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE students (
  student_id INT PRIMARY KEY,
  student_name VARCHAR(100) NOT NULL,
  age INT,
  city VARCHAR(50),
  dept_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- 4) Seed data
INSERT INTO departments (dept_id, dept_name)
VALUES
  (10, 'Computer Science'),
  (20, 'Electronics'),
  (30, 'Mechanical');

INSERT INTO students (student_id, student_name, age, city, dept_id)
VALUES
  (1, 'Aarav', 20, 'Delhi', 10),
  (2, 'Ishita', 21, 'Mumbai', 20),
  (3, 'Kabir', 19, 'Pune', 10),
  (4, 'Riya', 22, 'Bengaluru', 30),
  (5, 'Dev', 20, 'Delhi', 10);

-- 5) Quick sanity check
SELECT * FROM departments;
SELECT * FROM students;
