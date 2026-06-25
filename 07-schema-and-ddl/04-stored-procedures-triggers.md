# Stored Procedures, Triggers & Functions — Server-Side SQL Logic

> **Interview Priority**: 🟡 Important

## What Is It?

**Stored Procedure**: A named, pre-compiled block of SQL (and procedural logic) stored inside the database. You call it by name. It can accept input, produce output, and contain control flow (IF, LOOP, etc.). Think of it as a "SQL function" that the database runs entirely on its server side.

**Trigger**: A special procedure that **automatically fires** in response to a DML event (`INSERT`, `UPDATE`, or `DELETE`) on a specific table. You don't call triggers — the database calls them for you. Common uses: audit logging, enforcing business rules, cascading updates.

**User-Defined Function (UDF)**: Similar to a stored procedure but **always returns a value** and can be used inside a SELECT statement (like a built-in function). Cannot produce side effects (no INSERT/UPDATE inside a function in most databases).

---

## Syntax

```sql
-- ── STORED PROCEDURE (MySQL) ─────────────────────────────────
DELIMITER $$

CREATE PROCEDURE procedure_name (
    IN  param1  datatype,
    IN  param2  datatype,
    OUT result  datatype
)
BEGIN
    -- SQL statements
END$$

DELIMITER ;

-- Call a stored procedure
CALL procedure_name(arg1, arg2, @output_var);
SELECT @output_var;   -- retrieve OUT parameter

-- Drop a procedure
DROP PROCEDURE IF EXISTS procedure_name;

-- ── STORED PROCEDURE (PostgreSQL — uses PL/pgSQL) ────────────
CREATE OR REPLACE PROCEDURE procedure_name (
    IN param1  datatype,
    IN param2  datatype
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- SQL statements
END;
$$;

CALL procedure_name(arg1, arg2);

-- ── TRIGGER ─────────────────────────────────────────────────
CREATE TRIGGER trigger_name
{ BEFORE | AFTER | INSTEAD OF }
{ INSERT | UPDATE | DELETE }
ON table_name
FOR EACH ROW
[WHEN (condition)]
BEGIN
    -- trigger body (MySQL)
END;

-- PostgreSQL triggers require a trigger function:
CREATE OR REPLACE FUNCTION trigger_function_name()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- NEW holds the new row (INSERT/UPDATE)
    -- OLD holds the old row (UPDATE/DELETE)
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_name
AFTER UPDATE ON table_name
FOR EACH ROW
EXECUTE FUNCTION trigger_function_name();

-- Drop trigger
DROP TRIGGER trigger_name ON table_name;   -- PostgreSQL
DROP TRIGGER trigger_name;                  -- MySQL (inside table context)

-- ── USER-DEFINED FUNCTION ────────────────────────────────────
CREATE FUNCTION function_name(param datatype)
RETURNS return_type
[DETERMINISTIC]
BEGIN
    RETURN expression;
END;

-- Use inside SELECT:
SELECT function_name(salary) FROM employees;
```

---

## Key Concepts

### Stored Procedures

- **Pre-compiled** — parsed and optimized once, then cached. Repeated calls are faster than sending ad-hoc SQL.
- **IN parameters** — values passed into the procedure (read-only inside).
- **OUT parameters** — values the procedure writes back to the caller.
- **INOUT parameters** — both read and written.
- **Reusability** — define business logic once, call from any application or script.
- **Security** — grant EXECUTE permission on the procedure without granting direct table access (principle of least privilege).
- **Network efficiency** — one round-trip to execute a complex operation instead of many.
- **Transactions inside procedures** — procedures can contain `BEGIN`, `COMMIT`, `ROLLBACK`.
- **Drawbacks** — logic is hidden in the DB (harder to version-control), can lead to "stored procedure sprawl", harder to unit test, business logic split between app and DB layers.

### Triggers

- **Event-driven** — fires automatically on INSERT, UPDATE, or DELETE.
- **BEFORE trigger** — fires before the DML operation; can modify `NEW` values or cancel the operation.
- **AFTER trigger** — fires after the DML completes; used for logging, notifications, cascading.
- **`NEW` and `OLD` pseudo-rows:**
  - `NEW` — the row being inserted or the post-update version (INSERT, UPDATE).
  - `OLD` — the row being deleted or the pre-update version (UPDATE, DELETE).
- **FOR EACH ROW** — trigger fires once per affected row (row-level). Most common.
- **FOR EACH STATEMENT** — trigger fires once per SQL statement (statement-level, PostgreSQL).
- **Dangers of triggers:** hidden logic (hard to debug), cascading triggers (trigger fires trigger fires trigger), performance impact, makes unit testing harder.
- **`INSTEAD OF` triggers** — on PostgreSQL/SQL Server: redirect the DML to different logic (common with views).

### User-Defined Functions

- **Returns exactly one value** (scalar) — can be used in SELECT, WHERE, ORDER BY.
- **DETERMINISTIC** — declaring a function deterministic (same inputs → same output) allows the optimizer to cache results.
- **Cannot cause side effects** in most DBs (no INSERT/UPDATE in a pure function — use procedures for that).
- **Scalar vs Table-Valued** — some databases support functions that return a result set (table-valued functions).

---

## Examples

### 1. Stored Procedure — give a bonus to all employees in a department

```sql
DELIMITER $$

CREATE PROCEDURE give_department_bonus (
    IN  p_dept_id    INT,
    IN  p_bonus_pct  DECIMAL(5,2),
    OUT p_rows_updated INT
)
BEGIN
    -- Apply percentage bonus to salary
    UPDATE employees
    SET salary = salary * (1 + p_bonus_pct / 100)
    WHERE dept_id = p_dept_id;

    -- Capture how many rows were affected
    SET p_rows_updated = ROW_COUNT();

    -- Also insert into performance table as a bonus record
    INSERT INTO performance (emp_id, year, rating, bonus)
    SELECT emp_id, YEAR(CURDATE()), 'A', salary * (p_bonus_pct / 100)
    FROM employees
    WHERE dept_id = p_dept_id;
END$$

DELIMITER ;

-- Give Engineering (dept_id=10) a 10% bonus:
CALL give_department_bonus(10, 10.00, @updated);
SELECT @updated AS employees_updated;
-- employees_updated: 2  (Aman and Dev)
```

### 2. Stored Procedure — find employees above a salary threshold (IN param, SELECT output)

```sql
DELIMITER $$

CREATE PROCEDURE get_high_earners (
    IN p_min_salary DECIMAL(10,2)
)
BEGIN
    SELECT emp_id, name, salary, dept_id
    FROM employees
    WHERE salary >= p_min_salary
    ORDER BY salary DESC;
END$$

DELIMITER ;

-- Call it:
CALL get_high_earners(75000.00);
/*
emp_id | name | salary   | dept_id
-------|------|----------|--------
3      | Ravi | 91000.00 | 30
1      | Aman | 85000.00 | 10
5      | Dev  | 78000.00 | 10
*/
```

### 3. Stored Procedure — PostgreSQL version

```sql
CREATE OR REPLACE PROCEDURE give_department_bonus(
    p_dept_id    INT,
    p_bonus_pct  DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET salary = salary * (1 + p_bonus_pct / 100)
    WHERE dept_id = p_dept_id;

    RAISE NOTICE 'Bonus applied to dept %', p_dept_id;
END;
$$;

-- Call:
CALL give_department_bonus(10, 10.0);
```

### 4. AFTER UPDATE Trigger — salary audit log

First, create the audit table:

```sql
CREATE TABLE salary_audit (
    audit_id    INT AUTO_INCREMENT PRIMARY KEY,
    emp_id      INT,
    old_salary  DECIMAL(10,2),
    new_salary  DECIMAL(10,2),
    changed_by  VARCHAR(100),
    changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

Now the trigger (MySQL):

```sql
DELIMITER $$

CREATE TRIGGER trg_salary_audit
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    -- Only log if salary actually changed
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO salary_audit (emp_id, old_salary, new_salary, changed_by)
        VALUES (OLD.emp_id, OLD.salary, NEW.salary, CURRENT_USER());
    END IF;
END$$

DELIMITER ;

-- Now when salary changes:
UPDATE employees SET salary = 95000 WHERE emp_id = 3;  -- Ravi's salary

-- Audit log automatically records:
SELECT * FROM salary_audit;
/*
audit_id | emp_id | old_salary | new_salary | changed_by | changed_at
---------|--------|------------|------------|------------|--------------------
1        | 3      | 91000.00   | 95000.00   | root@localhost | 2024-06-15 10:30:00
*/
```

### 5. BEFORE INSERT Trigger — auto-normalize email to lowercase

```sql
DELIMITER $$

CREATE TRIGGER trg_normalize_email
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    SET NEW.email = LOWER(NEW.email);
END$$

DELIMITER ;

-- Now any insert automatically normalizes the email:
INSERT INTO employees (emp_id, name, dept_id, salary, hire_date, email)
VALUES (6, 'Neha', 20, 58000, '2024-01-15', 'NEHA@COMPANY.COM');

SELECT email FROM employees WHERE emp_id = 6;
-- Result: neha@company.com  (automatically lowercased by trigger)
```

### 6. Trigger (PostgreSQL) — audit log pattern

```sql
-- Step 1: Create the trigger function
CREATE OR REPLACE FUNCTION fn_salary_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.salary IS DISTINCT FROM NEW.salary THEN
        INSERT INTO salary_audit (emp_id, old_salary, new_salary, changed_by)
        VALUES (OLD.emp_id, OLD.salary, NEW.salary, current_user);
    END IF;
    RETURN NEW;
END;
$$;

-- Step 2: Attach it to the table
CREATE TRIGGER trg_salary_audit
AFTER UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_salary_audit();
```

### 7. User-Defined Function — annual salary calculation

```sql
-- MySQL
DELIMITER $$

CREATE FUNCTION annual_salary(monthly_salary DECIMAL(10,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    RETURN monthly_salary * 12;
END$$

DELIMITER ;

-- Use inside a query:
SELECT name, salary, annual_salary(salary) AS annual_ctc
FROM employees;
/*
name  | salary   | annual_ctc
------|----------|----------
Aman  | 85000.00 | 1020000.00
Priya | 62000.00 | 744000.00
*/
```

### 8. Calling a procedure with EXEC (SQL Server reference)

```sql
-- SQL Server uses EXEC instead of CALL:
EXEC give_department_bonus @p_dept_id = 10, @p_bonus_pct = 10.0;
```

---

## Stored Procedure vs Function vs Trigger

| Feature | Stored Procedure | Function (UDF) | Trigger |
|---|---|---|---|
| Called explicitly | ✅ Yes (`CALL`/`EXEC`) | ✅ Yes (in SQL) | ❌ Auto-fires |
| Returns value | Optional (OUT param) | ✅ Always | ❌ No |
| Used in SELECT | ❌ No | ✅ Yes | ❌ No |
| Can modify data | ✅ Yes | ❌ Usually not | ✅ Yes |
| Runs transactions | ✅ Yes | ❌ No | Inherits caller's txn |
| Use case | Business logic, batch ops | Computed values | Auditing, validation |

---

## Interview Tips

1. **"What is a stored procedure and why use it?"** — A pre-compiled SQL block stored in the DB. Benefits: reusability, reduced network round-trips, encapsulated business logic, and security (EXECUTE without SELECT/UPDATE grants). Drawback: logic lives in the DB — hard to version-control and test.

2. **"What is the difference between a stored procedure and a function?"** — A function always returns a value and can be embedded in a SELECT. A procedure is called standalone with CALL/EXEC, can have multiple OUT parameters, and can perform transactions and side effects.

3. **"What is NEW and OLD in a trigger?"** — `NEW` references the row as it will appear after the DML (INSERT new row, UPDATE new version). `OLD` references the row as it was before (UPDATE old version, DELETE deleted row). BEFORE triggers can modify `NEW` to alter what gets written.

4. **"What are the risks of using triggers?"** — Hidden logic (developers don't know the trigger exists), cascading triggers (trigger A fires trigger B fires trigger C), performance degradation on bulk operations, and debugging difficulty. Many teams ban triggers in production for these reasons.

5. **"When would you choose a stored procedure over application-side code?"** — When the operation is computationally heavy and data-intensive (processes millions of rows — less network transfer), when the same logic must be shared across multiple applications or languages, or when you need database-level security boundaries.

---

## ❓ Practice Questions

1. Write a stored procedure `add_performance_review` that takes `emp_id INT`, `p_year INT`, `p_rating CHAR(1)`, and `p_bonus DECIMAL(10,2)` as IN parameters and inserts a row into the `performance` table. Include a check: if a record already exists for that `emp_id` and `year`, UPDATE it instead of inserting.

2. Create an AFTER INSERT trigger on the `orders` table that, whenever a new order is inserted with `status = 'Completed'`, inserts a record into a `completed_order_log` table with `order_id`, `customer_id`, `amount`, and `logged_at` (current timestamp).

3. Write a BEFORE UPDATE trigger on the `employees` table that prevents any salary reduction (i.e., if `NEW.salary < OLD.salary`, it should raise an error or reset `NEW.salary = OLD.salary`). Show the MySQL and PostgreSQL versions.

4. Create a stored procedure `dept_salary_report` that accepts a `dept_id INT` and returns the department name, headcount, average salary, and total payroll by joining `employees` and `departments`. Call it for the Engineering department.

5. Explain the potential problem with the following design: a trigger on `orders` AFTER INSERT fires a stored procedure that updates `customers.total_spent`, which itself fires another trigger on `customers` AFTER UPDATE that logs to a `customer_activity_log` table. What could go wrong, and how would you redesign this?
