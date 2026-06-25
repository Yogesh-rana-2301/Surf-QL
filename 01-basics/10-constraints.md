# Constraints — Enforcing Data Integrity at the Schema Level

> **Interview Priority**: 🔴 Must Know

## What Is It?

Constraints are rules defined on columns or tables that the database engine enforces automatically. They act as a safety net — preventing invalid, duplicate, or orphaned data from ever entering the database. Constraints shift data validation from application code (unreliable, can be bypassed) to the database layer (always enforced, regardless of how data is inserted).

## Syntax

```sql
-- Column-level (inline with column definition)
column_name  datatype  CONSTRAINT_NAME

-- Table-level (after all column definitions, required for composite keys)
CONSTRAINT constraint_name  CONSTRAINT_TYPE (column_list)

-- Adding a constraint to an existing table
ALTER TABLE table_name ADD CONSTRAINT constraint_name CONSTRAINT_TYPE (column);

-- Dropping a constraint
ALTER TABLE table_name DROP CONSTRAINT constraint_name;   -- ANSI SQL / PostgreSQL
ALTER TABLE table_name DROP INDEX index_name;             -- MySQL (for UNIQUE)
ALTER TABLE table_name DROP FOREIGN KEY fk_name;         -- MySQL (for FK)
```

## Key Concepts

### 1. PRIMARY KEY

- Uniquely identifies each row. Implicitly `NOT NULL` + `UNIQUE`.
- One per table (but can span multiple columns — composite PK).
- Automatically creates a clustered index (in most RDBMS).

```sql
CREATE TABLE departments (
    dept_id   INT         PRIMARY KEY,    -- column-level
    dept_name VARCHAR(100) NOT NULL,
    location  VARCHAR(100) NOT NULL
);

-- Composite primary key (table-level — required for multi-column PKs)
CREATE TABLE project_assignments (
    emp_id     INT NOT NULL,
    project_id INT NOT NULL,
    role       VARCHAR(50),
    PRIMARY KEY (emp_id, project_id)      -- table-level composite PK
);
```

### 2. FOREIGN KEY

- Enforces referential integrity — the value in the child column must exist in the parent column.
- Prevents orphaned rows (e.g., an order for a non-existent customer).
- Reference actions: `ON DELETE CASCADE | RESTRICT | SET NULL | NO ACTION`

```sql
CREATE TABLE employees (
    emp_id     INT PRIMARY KEY,
    dept_id    INT,
    manager_id INT,
    -- ...
    FOREIGN KEY (dept_id)    REFERENCES departments(dept_id) ON DELETE SET NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)   ON DELETE SET NULL
);
```

### 3. UNIQUE

- No two rows may have the same value in the column(s).
- Unlike PRIMARY KEY, a table can have **multiple** UNIQUE constraints.
- `NULL` values are permitted and are **not considered duplicates** of each other (a UNIQUE column can have multiple NULLs).

```sql
CREATE TABLE employees (
    emp_id INT  PRIMARY KEY,
    email  VARCHAR(120) UNIQUE NOT NULL   -- unique per employee
);

-- Composite unique: one rating record per employee per year
UNIQUE (emp_id, year)
```

### 4. NOT NULL

- Prevents a column from storing `NULL`. Every insert/update must provide a value.
- The most basic and commonly used constraint.

```sql
CREATE TABLE customers (
    customer_id INT          PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,    -- name is mandatory
    city        VARCHAR(100),             -- city is optional (nullable)
    email       VARCHAR(120) UNIQUE NOT NULL
);
```

### 5. DEFAULT

- Provides an automatic value when a column is omitted from an `INSERT`.
- Does NOT prevent NULLs — you can still explicitly `INSERT NULL` into a column with DEFAULT (unless combined with NOT NULL).

```sql
CREATE TABLE orders (
    order_id   INT           PRIMARY KEY,
    status     VARCHAR(50)   NOT NULL DEFAULT 'pending',    -- auto-set if omitted
    order_date DATE          NOT NULL DEFAULT (CURRENT_DATE)
);

INSERT INTO orders (order_id, customer_id, product_id, amount)
VALUES (13, 1, 2, 3499.00);
-- status = 'pending', order_date = today — set automatically
```

### 6. CHECK

- Validates column values against a boolean expression.
- Rows that violate the CHECK condition are rejected.
- MySQL enforced CHECK since version 8.0.16.

```sql
CREATE TABLE performance (
    perf_id INT    PRIMARY KEY,
    emp_id  INT    NOT NULL,
    rating  CHAR(1) NOT NULL,
    bonus   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CHECK (rating IN ('A', 'B', 'C')),             -- only valid grades
    CHECK (bonus >= 0)                             -- no negative bonuses
);

CREATE TABLE orders (
    -- ...
    CHECK (status IN ('completed', 'pending', 'cancelled'))
);
```

## Adding Constraints with ALTER TABLE

```sql
-- Add a NOT NULL constraint (requires modifying the column definition in MySQL)
ALTER TABLE employees MODIFY COLUMN email VARCHAR(120) NOT NULL;

-- Add a UNIQUE constraint
ALTER TABLE employees ADD CONSTRAINT uq_email UNIQUE (email);

-- Add a CHECK constraint
ALTER TABLE performance ADD CONSTRAINT chk_rating CHECK (rating IN ('A', 'B', 'C'));

-- Add a FOREIGN KEY constraint
ALTER TABLE employees
ADD CONSTRAINT fk_dept
FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE SET NULL;

-- Add a DEFAULT value
ALTER TABLE orders ALTER COLUMN status SET DEFAULT 'pending';   -- MySQL syntax
ALTER TABLE orders ALTER status SET DEFAULT 'pending';          -- PostgreSQL syntax

-- Drop a FOREIGN KEY (MySQL)
ALTER TABLE employees DROP FOREIGN KEY fk_dept;

-- Drop a UNIQUE constraint (MySQL)
ALTER TABLE employees DROP INDEX uq_email;

-- Drop a CHECK constraint (MySQL 8+)
ALTER TABLE performance DROP CHECK chk_rating;
```

## Full Example: Recreating Our Schema with Named Constraints

```sql
CREATE TABLE departments (
    dept_id   INT          NOT NULL,
    dept_name VARCHAR(100) NOT NULL,
    location  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_departments PRIMARY KEY (dept_id)
);

CREATE TABLE employees (
    emp_id     INT           NOT NULL,
    name       VARCHAR(100)  NOT NULL,
    dept_id    INT,
    manager_id INT,
    salary     DECIMAL(10,2) NOT NULL,
    hire_date  DATE          NOT NULL,
    email      VARCHAR(120)  NOT NULL,

    CONSTRAINT pk_employees  PRIMARY KEY (emp_id),
    CONSTRAINT uq_emp_email  UNIQUE      (email),
    CONSTRAINT fk_emp_dept   FOREIGN KEY (dept_id)    REFERENCES departments(dept_id) ON DELETE SET NULL,
    CONSTRAINT fk_emp_mgr    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)   ON DELETE SET NULL
);

CREATE TABLE performance (
    perf_id INT           NOT NULL,
    emp_id  INT           NOT NULL,
    year    INT           NOT NULL,
    rating  CHAR(1)       NOT NULL,
    bonus   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT pk_performance  PRIMARY KEY (perf_id),
    CONSTRAINT fk_perf_emp     FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    CONSTRAINT uq_perf_emp_yr  UNIQUE (emp_id, year),
    CONSTRAINT chk_rating      CHECK  (rating IN ('A', 'B', 'C')),
    CONSTRAINT chk_bonus       CHECK  (bonus >= 0)
);
```

## Interview Tips

1. **PRIMARY KEY vs UNIQUE KEY**: This is asked constantly. Both enforce uniqueness. Differences: (a) A table can have only **one** PRIMARY KEY but **multiple** UNIQUE keys. (b) PRIMARY KEY columns are implicitly NOT NULL; UNIQUE columns can store NULLs (multiple NULLs are allowed). (c) Primary key creates a clustered index; unique key creates a non-clustered (secondary) index.

2. **UNIQUE allows multiple NULLs**: A `UNIQUE` constraint on `email` allows `NULL` in multiple rows — because `NULL != NULL` in SQL. If you need "unique or not provided", a UNIQUE nullable column is correct. If the value is always required, combine `UNIQUE NOT NULL`.

3. **Foreign key vs application-level validation**: Interviewers ask why use FK constraints when you can check in application code. Answer: DB constraints are enforced regardless of which application or service writes to the database. Direct SQL writes, migrations, scripts — all go through the constraint. Application code can be bypassed.

4. **CHECK constraints and MySQL version**: MySQL silently ignored CHECK constraints before version 8.0.16. If your team uses older MySQL, CHECK constraints in your schema are parsed but not enforced. Always verify the MySQL version when relying on CHECK.

5. **Named constraints are better than anonymous ones**: `CONSTRAINT fk_emp_dept FOREIGN KEY ...` vs just `FOREIGN KEY ...`. Named constraints produce clearer error messages (`FOREIGN KEY constraint fk_emp_dept fails`) and can be dropped by name. Anonymous constraints get system-generated names that vary across environments.

## ❓ Practice Questions

1. Write a `CREATE TABLE` for an `internships` table with: `intern_id` (PK, auto-increment), `name` (NOT NULL), `dept_id` (FK to `departments`), `stipend` (DECIMAL, must be ≥ 0, DEFAULT 0), and `joining_date` (DATE, NOT NULL). Use named constraints.

2. What is the difference between `PRIMARY KEY` and `UNIQUE KEY`? Give an example of a column in our `employees` or `customers` table that uses each, and explain why.

3. The `performance` table should ensure each employee has at most one record per year. Write the `ALTER TABLE` statement to add this composite unique constraint to an already-existing `performance` table.

4. A developer adds `CHECK (salary > 0)` to the `employees` table in a MySQL 5.7 database. They insert a row with `salary = -5000` and it succeeds without error. What went wrong, and how would you ensure the constraint is actually enforced?

5. Write the `ALTER TABLE` statements to: (a) add a `FOREIGN KEY` from `performance.emp_id` to `employees.emp_id`, and (b) drop the foreign key again (use MySQL syntax). Name the constraint `fk_perf_emp`.
