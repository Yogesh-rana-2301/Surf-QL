# ACID Properties & Isolation Levels — The Guarantees That Make Databases Trustworthy

> **Interview Priority**: 🔴 Must Know

## What Is It?

**ACID** is a set of four properties that guarantee database transactions are processed reliably, even in the presence of errors, crashes, and concurrent users. Every production-grade relational database (MySQL, PostgreSQL, Oracle, SQL Server) implements ACID guarantees — they are what separate a database from a spreadsheet.

**Isolation Levels** control how much concurrent transactions can "see" each other's in-progress work. They're the tuning knob between strict consistency (slow) and performance (potentially inconsistent).

**DCL (Data Control Language)** — `GRANT` and `REVOKE` — controls who is allowed to do what in the database (covered briefly at the end).

---

## ACID Properties

### A — Atomicity: All or Nothing

A transaction is **indivisible**. Every statement inside it either all commits or all rolls back. There is no such thing as "half a transaction" succeeding.

```sql
-- Bank transfer: BOTH updates must succeed or NEITHER does
BEGIN;

UPDATE employees SET salary = salary - 5000 WHERE emp_id = 3;   -- Debit Ravi
UPDATE employees SET salary = salary + 5000 WHERE emp_id = 1;   -- Credit Aman

-- If the server crashes HERE, after the first UPDATE but before the second:
-- On restart, the database reads the WAL log, sees the transaction never committed,
-- and UNDOES the first UPDATE. Ravi's salary is restored to 91000. Aman unchanged.

COMMIT;
```

**Real-world analogy:** Sending a wire transfer. The money is either debited AND credited, or the whole thing is cancelled. The bank can't debit you without crediting the recipient.

---

### C — Consistency: Valid State Always

A transaction takes the database from one **valid state** to another valid state. It can never leave the database in a state that violates defined rules — constraints, referential integrity, check constraints, triggers.

```sql
-- The employees table has a FK: dept_id → departments
-- This INSERT violates the FK constraint (dept_id=99 doesn't exist):
BEGIN;

INSERT INTO employees (emp_id, name, dept_id, salary, hire_date, email)
VALUES (10, 'Ghost', 99, 60000, '2024-01-01', 'ghost@company.com');
-- ❌ ERROR: Foreign key constraint fails (dept_id 99 not in departments)

ROLLBACK;  -- DB stays consistent — no partial row inserted
```

**Real-world analogy:** An accounting ledger must always balance. You can't add a debit without a matching credit.

> Note: Consistency is the one ACID property enforced by the **application + schema design** (constraints, rules), not solely by the database engine itself. Atomicity, Isolation, and Durability are engine guarantees.

---

### I — Isolation: Concurrent Transactions Don't Corrupt Each Other

Concurrent transactions execute as if they were **serial** (one at a time). One transaction's partial work is invisible to others — until it commits. This is managed through **locking** and **MVCC (Multi-Version Concurrency Control)**.

```sql
-- Session A opens a transaction:
-- Session A:
BEGIN;
UPDATE employees SET salary = 100000 WHERE emp_id = 1;  -- uncommitted

-- Session B immediately queries:
-- Session B:
SELECT salary FROM employees WHERE emp_id = 1;
-- Returns: 85000 (original value) — NOT 100000
-- Because Session A has NOT committed yet.

-- Session A:
COMMIT;

-- Session B queries again:
SELECT salary FROM employees WHERE emp_id = 1;
-- Now returns: 100000 (committed value)
```

The degree of isolation is configurable — see Isolation Levels below.

---

### D — Durability: Committed Data Survives Crashes

Once a `COMMIT` succeeds, the data is **permanently stored** — even if the server crashes a millisecond later. This is achieved via the **Write-Ahead Log (WAL)** / **redo log**: the commit record is written to durable storage before the COMMIT confirmation is returned to the client.

```sql
BEGIN;
INSERT INTO orders (order_id, customer_id, product_id, amount, order_date, status)
VALUES (9001, 101, 5, 2500.00, '2024-06-15', 'Completed');
COMMIT;
-- The COMMIT returns → data is on disk.
-- Server immediately loses power.
-- On restart: the WAL log shows the committed transaction.
-- The data is there. ✅
```

**Real-world analogy:** Saving a Word document — once you click Save and the dialog closes, the file is on disk. A power cut after that doesn't lose it.

---

## Isolation Levels

When multiple transactions run concurrently, three problems can occur:

### The Three Concurrency Problems

**1. Dirty Read** — Reading **uncommitted** data from another transaction.

```
Session A:  BEGIN; UPDATE employees SET salary = 999999 WHERE emp_id=1;
Session B:  SELECT salary FROM employees WHERE emp_id=1;  -- sees 999999 ← DIRTY READ
Session A:  ROLLBACK;  -- Session B read data that never actually existed!
```

**2. Non-Repeatable Read** — Reading the same row twice in one transaction and getting **different values** because another transaction committed a change in between.

```
Session A:  BEGIN;
Session A:  SELECT salary FROM employees WHERE emp_id=1;  -- returns 85000
Session B:  UPDATE employees SET salary=90000 WHERE emp_id=1; COMMIT;
Session A:  SELECT salary FROM employees WHERE emp_id=1;  -- returns 90000 ← changed!
Session A:  COMMIT;
```

**3. Phantom Read** — Re-executing a range query in one transaction and getting **different rows** because another transaction inserted or deleted rows.

```
Session A:  BEGIN;
Session A:  SELECT COUNT(*) FROM employees WHERE dept_id=10;  -- returns 2
Session B:  INSERT INTO employees VALUES (6,'Neha',10,58000,'2024-01-01','neha@x.com'); COMMIT;
Session A:  SELECT COUNT(*) FROM employees WHERE dept_id=10;  -- returns 3 ← phantom row!
Session A:  COMMIT;
```

---

### The Four Isolation Levels

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Performance |
|---|:---:|:---:|:---:|:---:|
| **READ UNCOMMITTED** | ✅ Possible | ✅ Possible | ✅ Possible | Fastest |
| **READ COMMITTED** | ❌ Prevented | ✅ Possible | ✅ Possible | Fast |
| **REPEATABLE READ** | ❌ Prevented | ❌ Prevented | ✅ Possible* | Moderate |
| **SERIALIZABLE** | ❌ Prevented | ❌ Prevented | ❌ Prevented | Slowest |

> *MySQL InnoDB's REPEATABLE READ also **prevents phantom reads** via gap locks — a MySQL-specific implementation detail that goes beyond the SQL standard.

---

### READ UNCOMMITTED — Sees everything, even uncommitted garbage

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN;
-- Can see another session's uncommitted dirty data
-- Fastest but most dangerous — almost never used in production
SELECT * FROM employees;
COMMIT;
```

**Use case:** Almost none. Possibly for rough real-time dashboards where a slightly wrong number is acceptable.

---

### READ COMMITTED — The safe minimum (PostgreSQL default)

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN;
-- Each statement sees data committed *before that statement executed*
-- No dirty reads, but values can change between two SELECTs in the same transaction
SELECT salary FROM employees WHERE emp_id = 1;  -- 85000
-- (another session commits UPDATE salary=90000)
SELECT salary FROM employees WHERE emp_id = 1;  -- 90000 ← non-repeatable read
COMMIT;
```

**Use case:** Most OLTP applications (banking, e-commerce). PostgreSQL default.

---

### REPEATABLE READ — Consistent snapshot (MySQL InnoDB default)

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN;
-- The transaction takes a snapshot of committed data at the time of the first read
SELECT salary FROM employees WHERE emp_id = 1;  -- 85000
-- (another session commits UPDATE salary=90000)
SELECT salary FROM employees WHERE emp_id = 1;  -- 85000 ← still same! snapshot held
COMMIT;
```

**MySQL InnoDB specific:** Also prevents phantom reads for most cases via **gap locking**.

**Use case:** Reports and analytics that read the same data multiple times and need a consistent view. MySQL default.

---

### SERIALIZABLE — The strictest, like running one transaction at a time

```sql
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN;
SELECT COUNT(*) FROM employees WHERE dept_id = 10;  -- 2
-- Another session tries to INSERT a new Engineering employee → BLOCKED
-- Until this transaction commits, the INSERT waits
COMMIT;
-- Now the other session's INSERT can proceed
```

**How it works:** Range locks (or predicate locks) prevent other transactions from inserting rows that would affect your query.

**Use case:** Financial reconciliation, inventory reservation, anywhere correctness is more important than throughput. Use sparingly — can cause lock contention and deadlocks.

---

### Full Comparison: Which Level Prevents Which Problem

```
                  ┌───────────────────────────────────────────────────┐
                  │  ISOLATION LEVEL PROTECTION MATRIX                 │
                  ├──────────────────┬────────────┬────────────┬───────┤
                  │ Isolation Level  │Dirty Read  │Non-Rep Read│Phantom│
                  ├──────────────────┼────────────┼────────────┼───────┤
                  │ READ UNCOMMITTED │     ✗      │     ✗      │   ✗   │
                  │ READ COMMITTED   │     ✓      │     ✗      │   ✗   │
                  │ REPEATABLE READ  │     ✓      │     ✓      │  ✗*   │
                  │ SERIALIZABLE     │     ✓      │     ✓      │   ✓   │
                  └──────────────────┴────────────┴────────────┴───────┘
                  ✓ = Prevented    ✗ = Possible    *MySQL InnoDB prevents this
```

---

## Checking and Setting Isolation Levels

```sql
-- MySQL: check current level
SELECT @@transaction_isolation;           -- MySQL 8.0+
SELECT @@tx_isolation;                    -- MySQL 5.x

-- MySQL: set for current session
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- MySQL: set for next transaction only (one-time)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
...
COMMIT;

-- PostgreSQL: check current level
SHOW transaction_isolation;

-- PostgreSQL: set for current transaction
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
...
COMMIT;
```

**🎯 Interview Answer:** MySQL InnoDB's default isolation level is **REPEATABLE READ**. PostgreSQL's default is **READ COMMITTED**.

---

## MVCC — How Databases Achieve Isolation Without Locking Everything

Most modern databases use **Multi-Version Concurrency Control (MVCC)** instead of heavy read locks:

- On every write, the database keeps the **old version** of the row alongside the new one.
- Readers see the version of the row that was valid **at the start of their transaction** (or statement, depending on isolation level).
- Writers write new versions; readers read old versions — **readers don't block writers, writers don't block readers**.
- Old versions are cleaned up periodically (VACUUM in PostgreSQL, purge thread in MySQL InnoDB).

---

## GRANT and REVOKE — DCL (Data Control Language)

DCL commands manage **permissions** — who can do what to which objects.

### GRANT — Give a user permission

```sql
-- Grant SELECT on the employees table to a user
GRANT SELECT ON employees TO hr_user;

-- Grant multiple privileges
GRANT SELECT, INSERT, UPDATE ON orders TO app_user;

-- Grant ALL privileges on a schema (PostgreSQL)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_user;

-- Grant EXECUTE on a stored procedure
GRANT EXECUTE ON PROCEDURE give_department_bonus TO manager_role;

-- Grant via roles (modern approach)
CREATE ROLE readonly_role;
GRANT SELECT ON employees, departments, orders TO readonly_role;
GRANT readonly_role TO hr_user;       -- PostgreSQL
GRANT 'readonly_role' TO 'hr_user'@'localhost';  -- MySQL
```

### REVOKE — Remove a permission

```sql
-- Revoke SELECT from a user
REVOKE SELECT ON employees FROM hr_user;

-- Revoke all privileges
REVOKE ALL PRIVILEGES ON orders FROM app_user;

-- Revoke a role
REVOKE readonly_role FROM hr_user;   -- PostgreSQL
```

### WITH GRANT OPTION — Allow the grantee to pass the privilege

```sql
-- hr_user can now GRANT SELECT on employees to other users
GRANT SELECT ON employees TO hr_user WITH GRANT OPTION;

-- Revoking WITH GRANT OPTION also cascades to any grants hr_user made
REVOKE GRANT OPTION FOR SELECT ON employees FROM hr_user CASCADE;
```

### Common Permission Levels

| Command | What it allows |
|---|---|
| `SELECT` | Read rows |
| `INSERT` | Add new rows |
| `UPDATE` | Modify rows |
| `DELETE` | Remove rows |
| `EXECUTE` | Run stored procedure/function |
| `CREATE` | Create tables, indexes, etc. |
| `DROP` | Drop tables, views, etc. |
| `ALL PRIVILEGES` | All of the above |
| `REFERENCES` | Create foreign keys referencing a table |

---

## Interview Tips

1. **"Explain ACID with a real example."** — Use the bank transfer: Atomicity (both debit and credit or neither), Consistency (account balance can't go below allowed minimum), Isolation (another user's query doesn't see the in-progress transfer), Durability (once committed, a crash won't lose it). This is the textbook answer interviewers expect.

2. **"What isolation level does MySQL use by default and why?"** — **REPEATABLE READ**. MySQL InnoDB also prevents phantom reads in this level (via gap locks), which is stronger than the SQL standard requires. PostgreSQL defaults to **READ COMMITTED** — a common gotcha.

3. **"What is a dirty read?"** — Reading data from a transaction that hasn't committed yet. If that transaction rolls back, you read data that never actually existed. Prevented by READ COMMITTED and above.

4. **"What is the difference between non-repeatable read and phantom read?"** — Non-repeatable read: the **same row** returns different values in two reads within a transaction (another transaction updated it). Phantom read: the **same query** returns different **sets of rows** (another transaction inserted or deleted rows). One is about a changed row; the other is about new/missing rows.

5. **"Why not always use SERIALIZABLE?"** — Because it severely limits concurrency. Transactions block each other waiting for locks, causing timeouts and deadlocks at scale. Most applications use READ COMMITTED or REPEATABLE READ and handle edge cases in application logic. SERIALIZABLE is reserved for genuinely critical operations (financial reconciliation, inventory checkout).

---

## ❓ Practice Questions

1. A reporting job runs inside a transaction at REPEATABLE READ and executes two queries, 30 seconds apart, to count orders per customer. Meanwhile, another process inserts 500 new orders. Will the report's two COUNT queries return the same result? What isolation level guarantees this? What level would NOT guarantee it?

2. Explain what happens in this scenario and which ACID property it violates if the database did NOT have atomicity:
   - Transaction starts
   - `UPDATE orders SET status = 'Completed' WHERE order_id = 501`  ← succeeds
   - `INSERT INTO performance (emp_id, year, rating, bonus) VALUES (2, 2024, 'A', 5000)` ← fails due to a FK violation
   - Server auto-rollbacks the whole transaction

3. The `employees` table has `salary DECIMAL(10,2) CHECK (salary > 0)`. A transaction tries to set `salary = -1000` for emp_id=1. Which ACID property prevents this from persisting, and through which mechanism (constraint, lock, log)?

4. A team decides to use READ UNCOMMITTED isolation for their analytics dashboard that counts pending orders (`WHERE status = 'Pending'`). Describe a specific scenario using the `orders` table where a dirty read could cause the dashboard to display an incorrect count, and what business decision might be made incorrectly as a result.

5. Write the SQL to: (a) create a role `sales_read` with SELECT access on `customers`, `orders`, and `products`; (b) grant that role to a user `sales_analyst`; (c) later revoke the role from `sales_analyst`. Show both MySQL and PostgreSQL syntax where they differ.
