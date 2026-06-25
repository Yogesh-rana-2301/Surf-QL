# CREATE TABLE — Defining the Structure of Your Data

> **Interview Priority**: 🔴 Must Know

## What Is It?

`CREATE TABLE` defines the **structure (schema)** of a table — its column names, data types, and constraints. Think of it as designing a template that every row must conform to. Once created, the table is empty; you then fill it with `INSERT` statements. Getting the schema right upfront prevents costly `ALTER TABLE` migrations later.

## Syntax

```sql
CREATE TABLE table_name (
    column1  datatype  [constraint(s)],
    column2  datatype  [constraint(s)],
    ...
    [table-level constraints]
);

-- Safe version — won't error if table already exists
CREATE TABLE IF NOT EXISTS table_name ( ... );
```

## Key Concepts

**Common Data Types**

| Type | Use For | Example |
|---|---|---|
| `INT` | Whole numbers, IDs | `emp_id INT` |
| `BIGINT` | Large integers (> 2 billion) | `views BIGINT` |
| `DECIMAL(p,s)` | Exact decimals (money) | `salary DECIMAL(10,2)` |
| `FLOAT / DOUBLE` | Approximate decimals (scientific) | `temperature FLOAT` |
| `VARCHAR(n)` | Variable-length strings up to n chars | `name VARCHAR(100)` |
| `CHAR(n)` | Fixed-length strings (padded) | `rating CHAR(1)` |
| `DATE` | Calendar date (YYYY-MM-DD) | `hire_date DATE` |
| `DATETIME` | Date + time | `created_at DATETIME` |
| `BOOLEAN` / `TINYINT(1)` | True/False (MySQL stores as 0/1) | `is_active BOOLEAN` |
| `TEXT` | Long free-form text | `description TEXT` |

**Column Constraints (Inline)**

- `NOT NULL` — column must always have a value; NULLs are rejected
- `DEFAULT value` — value used when INSERT omits this column
- `UNIQUE` — no two rows can have the same value; NULLs are allowed (and not compared)
- `PRIMARY KEY` — combination of NOT NULL + UNIQUE; one per table
- `AUTO_INCREMENT` — automatically assigns next integer (MySQL); `SERIAL` in PostgreSQL
- `CHECK (condition)` — validates the value against a boolean expression
- `FOREIGN KEY` — enforces referential integrity between tables

**Table vs Column Level Constraints**

- Column-level: written inline with the column definition (single-column constraints)
- Table-level: written after all columns, required for **composite** primary/foreign keys

## Examples

```sql
-- Creating the departments table (parent — no foreign keys)
CREATE TABLE departments (
    dept_id   INT          PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    location  VARCHAR(100) NOT NULL
);
```

```sql
-- Creating the employees table (child — references departments and itself)
CREATE TABLE employees (
    emp_id     INT           PRIMARY KEY,
    name       VARCHAR(100)  NOT NULL,
    dept_id    INT,                         -- nullable: some employees may be unassigned
    manager_id INT,                         -- self-referencing FK; NULL for the CEO
    salary     DECIMAL(10,2) NOT NULL,
    hire_date  DATE          NOT NULL,
    email      VARCHAR(120)  UNIQUE NOT NULL,

    -- Table-level foreign key constraints
    FOREIGN KEY (dept_id)    REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);
```

```sql
-- Creating the orders table with a CHECK constraint on status
CREATE TABLE orders (
    order_id    INT           PRIMARY KEY,
    customer_id INT           NOT NULL,
    product_id  INT           NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    order_date  DATE          NOT NULL,
    status      VARCHAR(50)   NOT NULL DEFAULT 'pending',

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    CHECK (status IN ('completed', 'pending', 'cancelled'))
);
```

```sql
-- AUTO_INCREMENT primary key example (very common in real apps)
CREATE TABLE audit_log (
    log_id     INT          PRIMARY KEY AUTO_INCREMENT,
    emp_id     INT          NOT NULL,
    action     VARCHAR(200) NOT NULL,
    logged_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);
```

```sql
-- Composite PRIMARY KEY (table-level) — e.g., one performance record per employee per year
CREATE TABLE performance (
    perf_id INT           PRIMARY KEY,
    emp_id  INT           NOT NULL,
    year    INT           NOT NULL,
    rating  CHAR(1)       NOT NULL,
    bonus   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    CHECK (rating IN ('A', 'B', 'C')),
    UNIQUE (emp_id, year)    -- each employee can have only one record per year
);
```

## Interview Tips

1. **`DECIMAL` vs `FLOAT` for money**: Always use `DECIMAL(10,2)` for financial values. `FLOAT` and `DOUBLE` are approximate — they can introduce rounding errors like `100.1 + 200.2 = 300.29999...`. Interviewers often ask this directly.

2. **Parent table before child table**: You cannot create `employees` before `departments` if `employees` has a FK to `departments`. Foreign key references require the parent table to already exist. Always define parents first.

3. **`NULL` is not zero or empty string**: A nullable column with no value is `NULL` — unknown. `NOT NULL` columns must receive a value on every insert (unless a `DEFAULT` is set). This is a very common interview gotcha.

4. **`VARCHAR` vs `CHAR`**: `CHAR(n)` always stores exactly n bytes (pads with spaces). `VARCHAR(n)` stores only the actual characters + 1-2 bytes for length. Use `CHAR` for fixed-width values like `rating CHAR(1)` or country codes; `VARCHAR` for variable-length like names.

5. **`PRIMARY KEY` creates an index automatically**: Every primary key column gets an implicit index in all major RDBMS. This is why lookups by `emp_id` are fast. Interviewers may ask why PK lookups are O(log n).

## ❓ Practice Questions

1. Write the `CREATE TABLE` statement for the `customers` table with `customer_id` (PK), `name` (NOT NULL), `city` (nullable), and `email` (UNIQUE, NOT NULL). Use appropriate data types.

2. The `performance` table should enforce that no employee has more than one record per year. How would you add this constraint at the table level? Write the full `CREATE TABLE` statement.

3. What is the difference between `DECIMAL(10,2)` and `FLOAT`? Which would you use for the `salary` column in `employees`, and why?

4. Write a `CREATE TABLE` statement for a `project_assignments` table that records which employee is assigned to which project, with a composite primary key on `(emp_id, project_id)`, and foreign keys referencing `employees`.

5. You want to add a column `is_active BOOLEAN DEFAULT TRUE NOT NULL` to the `employees` table schema. Write the full `CREATE TABLE` for `employees` including this new column alongside all original columns.
