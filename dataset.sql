-- =============================================================================
-- SURF-QL SHARED DATASET
-- =============================================================================
-- This file contains the shared schema and sample data used across ALL topic
-- files in this repository. Every example, practice question, and interview
-- tip references these tables — so load this dataset once and you are ready
-- to run any query from any note.
--
-- TABLES
--   departments  — 4 rows  (Engineering, HR, Finance, Marketing)
--   employees    — 10 rows (realistic salaries, one CEO with NULL manager)
--   customers    — 8 rows  (Indian cities: Mumbai, Delhi, Bengaluru, Chennai)
--   products     — 8 rows  (categories: Electronics, Clothing, Food)
--   orders       — 12 rows (status: completed | pending | cancelled)
--   performance  — 8 rows  (ratings: A | B | C, years 2022–2024)
--
-- HOW TO USE
--   mysql -u root -p < dataset.sql          -- load from terminal
--   SOURCE /path/to/dataset.sql;            -- load from MySQL prompt
--   \i /path/to/dataset.sql                 -- load in psql (PostgreSQL)
--
-- NOTE: Run this file in order — foreign-key references require parent tables
-- to exist before child tables are created.
-- =============================================================================

-- -----------------------------------------------------------------------
-- 0. Create and select database
-- -----------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS surfql;
USE surfql;

-- -----------------------------------------------------------------------
-- 1. DEPARTMENTS
-- -----------------------------------------------------------------------
DROP TABLE IF EXISTS performance;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    dept_id   INT          PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    location  VARCHAR(100) NOT NULL
);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(10, 'Engineering', 'Bengaluru'),
(20, 'HR',          'Mumbai'),
(30, 'Finance',     'Delhi'),
(40, 'Marketing',   'Chennai');

-- -----------------------------------------------------------------------
-- 2. EMPLOYEES
-- -----------------------------------------------------------------------
-- emp_id = 1  → CEO (manager_id IS NULL)
-- emp_id = 11 → No department (dept_id IS NULL) — useful for OUTER JOIN demos
-- emp_id = 12 → No department (dept_id IS NULL) — useful for OUTER JOIN demos
CREATE TABLE employees (
    emp_id     INT            PRIMARY KEY,
    name       VARCHAR(100)   NOT NULL,
    dept_id    INT,                          -- nullable: some employees unassigned
    manager_id INT,                          -- nullable: CEO has no manager
    salary     DECIMAL(10,2)  NOT NULL,
    hire_date  DATE           NOT NULL,
    email      VARCHAR(120)   UNIQUE NOT NULL,
    FOREIGN KEY (dept_id)    REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

INSERT INTO employees (emp_id, name, dept_id, manager_id, salary, hire_date, email) VALUES
( 1, 'Arjun Mehta',   10,   NULL, 120000.00, '2015-03-01', 'arjun.mehta@company.com'),   -- CEO / Engineering head
( 2, 'Aman Sharma',   10,      1,  85000.00, '2018-07-15', 'aman.sharma@company.com'),   -- Engineering
( 3, 'Priya Nair',    20,      1,  62000.00, '2019-01-10', 'priya.nair@company.com'),    -- HR
( 4, 'Ravi Kumar',    30,      1,  91000.00, '2017-11-20', 'ravi.kumar@company.com'),    -- Finance
( 5, 'Zara Khan',     40,      1,  74000.00, '2020-05-05', 'zara.khan@company.com'),     -- Marketing
( 6, 'Dev Patel',     10,      2,  78000.00, '2021-02-28', 'dev.patel@company.com'),     -- Engineering, reports to Aman
( 7, 'Neha Gupta',    20,      3,  55000.00, '2022-08-01', 'neha.gupta@company.com'),    -- HR, reports to Priya
( 8, 'Rahul Verma',   30,      4,  67000.00, '2020-12-15', 'rahul.verma@company.com'),   -- Finance, reports to Ravi
( 9, 'Sneha Reddy',   40,      5,  69000.00, '2023-03-22', 'sneha.reddy@company.com'),   -- Marketing, reports to Zara
(10, 'Karan Singh',   10,      2,  82000.00, '2019-09-30', 'karan.singh@company.com'),   -- Engineering, reports to Aman
(11, 'Meera Joshi',  NULL,     1,  58000.00, '2024-01-05', 'meera.joshi@company.com'),   -- No dept assigned yet
(12, 'Aditya Roy',   NULL,     1,  61000.00, '2024-03-18', 'aditya.roy@company.com');    -- No dept assigned yet

-- -----------------------------------------------------------------------
-- 3. CUSTOMERS
-- -----------------------------------------------------------------------
CREATE TABLE customers (
    customer_id INT          PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    city        VARCHAR(100),
    email       VARCHAR(120) UNIQUE NOT NULL
);

INSERT INTO customers (customer_id, name, city, email) VALUES
(1, 'Amit Bose',       'Mumbai',    'amit.bose@gmail.com'),
(2, 'Divya Menon',     'Bengaluru', 'divya.menon@gmail.com'),
(3, 'Farhan Qureshi',  'Delhi',     'farhan.q@gmail.com'),
(4, 'Geeta Pillai',    'Chennai',   'geeta.p@gmail.com'),
(5, 'Harish Iyer',     'Mumbai',    'harish.iyer@gmail.com'),
(6, 'Ishaan Tomar',    'Delhi',     'ishaan.t@gmail.com'),
(7, 'Jaya Krishnan',   'Bengaluru', 'jaya.k@gmail.com'),
(8, 'Komal Desai',     'Pune',      'komal.desai@gmail.com');  -- Pune: no orders (anti-join demo)

-- -----------------------------------------------------------------------
-- 4. PRODUCTS
-- -----------------------------------------------------------------------
CREATE TABLE products (
    product_id   INT            PRIMARY KEY,
    product_name VARCHAR(100)   NOT NULL,
    category     VARCHAR(100)   NOT NULL,
    price        DECIMAL(10,2)  NOT NULL
);

INSERT INTO products (product_id, product_name, category, price) VALUES
(1, 'Laptop Pro 15',     'Electronics',  89999.00),
(2, 'Wireless Earbuds',  'Electronics',   3499.00),
(3, 'Smartphone X12',    'Electronics',  54999.00),
(4, 'Cotton Kurta',      'Clothing',      1299.00),
(5, 'Running Shoes',     'Clothing',      3799.00),
(6, 'Denim Jeans',       'Clothing',      2199.00),
(7, 'Basmati Rice 5kg',  'Food',           599.00),
(8, 'Cold Pressed Oil',  'Food',           849.00);

-- -----------------------------------------------------------------------
-- 5. ORDERS
-- -----------------------------------------------------------------------
-- Customers 7 (Jaya) and 8 (Komal) have NO orders — useful for anti-join demos
CREATE TABLE orders (
    order_id    INT            PRIMARY KEY,
    customer_id INT            NOT NULL,
    product_id  INT            NOT NULL,
    amount      DECIMAL(10,2)  NOT NULL,
    order_date  DATE           NOT NULL,
    status      VARCHAR(50)    NOT NULL DEFAULT 'pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    CHECK (status IN ('completed', 'pending', 'cancelled'))
);

INSERT INTO orders (order_id, customer_id, product_id, amount, order_date, status) VALUES
( 1, 1, 1,  89999.00, '2024-01-15', 'completed'),
( 2, 1, 2,   3499.00, '2024-02-10', 'completed'),
( 3, 2, 3,  54999.00, '2024-01-28', 'pending'),
( 4, 2, 5,   3799.00, '2024-03-05', 'completed'),
( 5, 3, 4,   1299.00, '2024-02-20', 'cancelled'),
( 6, 3, 6,   2199.00, '2024-03-15', 'pending'),
( 7, 4, 7,    599.00, '2024-01-10', 'completed'),
( 8, 4, 8,    849.00, '2024-02-28', 'completed'),
( 9, 5, 2,   3499.00, '2024-03-20', 'pending'),
(10, 5, 3,  54999.00, '2024-04-01', 'cancelled'),
(11, 6, 1,  89999.00, '2024-04-10', 'completed'),
(12, 6, 7,    599.00, '2024-04-18', 'pending');
-- customer_id 7 (Jaya Krishnan) and 8 (Komal Desai) intentionally have no orders

-- -----------------------------------------------------------------------
-- 6. PERFORMANCE
-- -----------------------------------------------------------------------
-- Ratings: A = Exceptional, B = Meets Expectations, C = Needs Improvement
CREATE TABLE performance (
    perf_id INT            PRIMARY KEY,
    emp_id  INT            NOT NULL,
    year    INT            NOT NULL,
    rating  CHAR(1)        NOT NULL,
    bonus   DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    CHECK (rating IN ('A', 'B', 'C'))
);

INSERT INTO performance (perf_id, emp_id, year, rating, bonus) VALUES
(1,  2, 2022, 'A', 12000.00),
(2,  2, 2023, 'B',  7500.00),
(3,  3, 2023, 'C',  2000.00),
(4,  4, 2022, 'A', 15000.00),
(5,  4, 2024, 'A', 16000.00),
(6,  5, 2023, 'B',  6000.00),
(7,  6, 2024, 'B',  8000.00),
(8,  9, 2024, 'C',  1500.00);

-- =============================================================================
-- QUICK REFERENCE
-- =============================================================================
-- SELECT * FROM departments;
-- SELECT * FROM employees;
-- SELECT * FROM customers;
-- SELECT * FROM products;
-- SELECT * FROM orders;
-- SELECT * FROM performance;
-- =============================================================================
