# 02) Creating Tables and Adding Data

After creating a database, you define table structure using `CREATE TABLE`.
Then you insert records with `INSERT INTO`.

## Create Table Syntax

```sql
CREATE TABLE table_name (
  column1 datatype constraints,
  column2 datatype constraints
);
```

## Example Tables

```sql
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
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
```

## Insert Data

```sql
INSERT INTO departments (dept_id, dept_name)
VALUES
  (10, 'Computer Science'),
  (20, 'Electronics'),
  (30, 'Mechanical');

INSERT INTO students (student_id, student_name, age, city, dept_id)
VALUES
  (1, 'Aarav', 20, 'Delhi', 10),
  (2, 'Ishita', 21, 'Mumbai', 20),
  (3, 'Kabir', 19, 'Pune', 10);
```

## Rules to Remember

- Primary key values must be unique.
- Foreign key values should exist in referenced table.
- `NOT NULL` columns must be provided.
- Column order in `INSERT INTO` should match value order.
