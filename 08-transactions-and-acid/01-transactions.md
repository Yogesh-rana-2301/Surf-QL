# Transactions — All or Nothing, Every Time

> **Interview Priority**: 🔴 Must Know

## What Is It?

A **transaction** is a logical unit of work that groups one or more SQL statements so they execute as a single atomic operation. Either **all statements succeed** and are permanently saved, or **none of them take effect** — the database rolls back to the state before the transaction began.

Transactions are the mechanism that keeps your data consistent when operations have multiple steps. The classic example is a bank transfer: debit one account and credit another. If the server crashes after the debit but before the credit, you've lost money. Transactions prevent this — if anything fails mid-way, everything is undone.

---

## Syntax

```sql
-- Start a transaction
BEGIN;                       -- Standard SQL / PostgreSQL
START TRANSACTION;           -- MySQL (both forms work in MySQL)

-- Commit: make all changes permanent
COMMIT;

-- Rollback: undo all changes since BEGIN
ROLLBACK;

-- Savepoint: create a named checkpoint within a transaction
SAVEPOINT savepoint_name;

-- Rollback to a specific savepoint (partial undo)
ROLLBACK TO SAVEPOINT savepoint_name;

-- Release (remove) a savepoint when no longer needed
RELEASE SAVEPOINT savepoint_name;

-- Autocommit control
SET autocommit = 0;   -- Disable autocommit (MySQL)
SET autocommit = 1;   -- Re-enable autocommit (MySQL)
```

---

## Key Concepts

### Autocommit

- **By default, most databases run in autocommit mode** — every individual SQL statement is automatically committed as its own transaction the moment it executes.
- In MySQL: `autocommit = 1` by default. Each `UPDATE`, `INSERT`, `DELETE` immediately commits.
- In PostgreSQL: also autocommit by default, but wraps each statement in an implicit transaction.
- When you write `BEGIN` / `START TRANSACTION`, you **override** autocommit for that block — the database waits for your explicit `COMMIT` or `ROLLBACK`.
- In application code, most database drivers disable autocommit so the developer controls commit boundaries.

### Explicit vs Implicit Transactions

| Type | Description |
|---|---|
| **Explicit** | Developer manually writes `BEGIN`, then `COMMIT` or `ROLLBACK`. Full control. |
| **Implicit** | Database auto-wraps each statement in its own transaction (autocommit = ON). No explicit BEGIN needed. |
| **Application-managed** | ORM frameworks (Hibernate, SQLAlchemy) manage transactions programmatically. |

### What Happens Inside a Transaction

- All changes are written to a **transaction log / WAL (Write-Ahead Log)** first, not directly to data files.
- Other sessions see the **old data** (uncommitted changes are invisible to others — depends on isolation level).
- On `COMMIT`: changes are permanently flushed to the data files. The log entries are marked committed.
- On `ROLLBACK`: the log entries are discarded; the database reverts to the pre-transaction state.

### Savepoints

- A savepoint is a named checkpoint **within** a transaction.
- You can roll back to a savepoint without rolling back the entire transaction.
- Useful when a large transaction has multiple phases — if phase 3 fails, roll back only phase 3, not phases 1 and 2.
- After a `ROLLBACK TO SAVEPOINT`, you can still `COMMIT` the portions before the savepoint.

---

## Examples

### 1. Classic Bank Transfer — the canonical transaction example

```sql
-- Scenario: Transfer 10,000 from Ravi (emp_id=3) to Aman (emp_id=1)
-- Both must succeed or neither should happen.

BEGIN;

UPDATE employees SET salary = salary - 10000 WHERE emp_id = 3;  -- Debit Ravi
-- (Ravi's salary: 91000 → 81000)

UPDATE employees SET salary = salary + 10000 WHERE emp_id = 1;  -- Credit Aman
-- (Aman's salary: 85000 → 95000)

-- Both succeeded — make it permanent:
COMMIT;
```

If anything fails between the two UPDATEs:

```sql
BEGIN;

UPDATE employees SET salary = salary - 10000 WHERE emp_id = 3;
-- Imagine a network timeout or constraint violation here...

ROLLBACK;
-- Ravi's salary is restored to 91000. Aman's salary unchanged. No money lost.
```

### 2. Order placement — transactional multi-table insert

```sql
-- Placing an order must insert into orders AND update product inventory atomically
BEGIN;

INSERT INTO orders (order_id, customer_id, product_id, amount, order_date, status)
VALUES (5001, 201, 10, 1500.00, CURDATE(), 'Pending');

-- Hypothetical inventory table update (illustrative)
UPDATE products SET stock = stock - 1 WHERE product_id = 10;

-- Only commit if BOTH operations succeed
COMMIT;
```

### 3. ROLLBACK on error — salary update gone wrong

```sql
BEGIN;

UPDATE employees SET salary = 200000 WHERE dept_id = 10;  -- Give Engineering a raise
-- Oh wait — wrong WHERE clause, this affects too many people

ROLLBACK;  -- Undo everything. No changes saved.

-- Now do the correct, targeted update:
BEGIN;
UPDATE employees SET salary = 95000 WHERE emp_id = 1;     -- Only Aman
COMMIT;
```

### 4. SAVEPOINT — multi-phase operation with partial rollback

```sql
BEGIN;

-- Phase 1: Promote Aman
UPDATE employees SET salary = 100000 WHERE emp_id = 1;
SAVEPOINT after_promotion;

-- Phase 2: Add a performance review
INSERT INTO performance (emp_id, year, rating, bonus)
VALUES (1, 2024, 'A', 10000);
SAVEPOINT after_review;

-- Phase 3: Adjust department budget (hypothetical table)
UPDATE departments SET budget = budget - 10000 WHERE dept_id = 10;
-- Suppose this fails with a constraint violation...

ROLLBACK TO SAVEPOINT after_review;
-- Phase 3 is undone; phases 1 and 2 are still in the transaction

-- We can still commit phases 1 and 2:
COMMIT;
```

### 5. Autocommit — single statement without BEGIN

```sql
-- With autocommit ON (default), this single UPDATE commits immediately:
UPDATE employees SET salary = 90000 WHERE emp_id = 5;
-- ↑ This is permanent. No way to ROLLBACK. There was no explicit transaction.

-- To make it rollback-able, wrap it:
BEGIN;
UPDATE employees SET salary = 90000 WHERE emp_id = 5;
-- Decision: accept or reject
ROLLBACK;  -- or COMMIT
```

### 6. SET autocommit = 0 (MySQL)

```sql
SET autocommit = 0;  -- Disable autocommit for this session

UPDATE employees SET salary = 80000 WHERE emp_id = 2;  -- Not yet committed
UPDATE employees SET salary = 85000 WHERE emp_id = 5;  -- Not yet committed

-- Now explicitly commit both:
COMMIT;

SET autocommit = 1;  -- Restore default behavior
```

### 7. Transaction with error handling (MySQL stored procedure pattern)

```sql
DELIMITER $$

CREATE PROCEDURE transfer_salary(
    IN from_emp INT,
    IN to_emp   INT,
    IN amount   DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transfer failed, rolled back.';
    END;

    START TRANSACTION;

    UPDATE employees SET salary = salary - amount WHERE emp_id = from_emp;
    UPDATE employees SET salary = salary + amount WHERE emp_id = to_emp;

    COMMIT;
END$$

DELIMITER ;

CALL transfer_salary(3, 1, 5000.00);  -- Safe transfer: auto-rolls back on any error
```

### 8. Checking transaction isolation in MySQL

```sql
-- Check current isolation level
SELECT @@transaction_isolation;         -- MySQL 8.0+
SELECT @@tx_isolation;                  -- MySQL 5.x

-- Set isolation level for the current session
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Set for the next single transaction
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
...
COMMIT;
```

---

## Explicit Transaction Flow Diagram

```
          ┌─────────────────────────────────────┐
          │           BEGIN / START TRANSACTION   │
          └────────────────────┬────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Execute SQL         │
                    │  (INSERT/UPDATE/DEL) │
                    └──────────┬──────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    Success? YES          SAVEPOINT            Error?
           │                   │                   │
      ┌────▼────┐       ┌──────▼──────┐    ┌──────▼──────┐
      │ COMMIT  │       │ Continue or │    │  ROLLBACK   │
      │(durable)│       │ ROLLBACK TO │    │(undo all or │
      └─────────┘       │  SAVEPOINT  │    │ to SAVEPOINT│
                        └─────────────┘    └─────────────┘
```

---

## Interview Tips

1. **"What is a transaction and why is it important?"** — A transaction groups multiple statements into an atomic unit: either all succeed (COMMIT) or all fail (ROLLBACK). This prevents partial updates that leave data in an inconsistent state.

2. **"What is autocommit and how does it affect transactions?"** — With autocommit ON (the default), every statement is its own transaction — committed immediately, not rollback-able. Explicit `BEGIN`…`COMMIT` overrides autocommit for that block.

3. **"What is a SAVEPOINT and when would you use it?"** — A checkpoint inside a transaction. You can roll back to it without rolling back everything. Useful in complex multi-step operations where you want fine-grained error recovery per phase.

4. **"If a server crashes after COMMIT, is the data safe?"** — Yes — this is the Durability guarantee (D in ACID). The COMMIT writes to the WAL/redo log on durable storage first. On restart, the database replays the log and the data is there.

5. **"What happens to other sessions' reads during your open transaction?"** — Depends on the **isolation level**. By default (REPEATABLE READ in MySQL), other sessions see the committed data snapshot from before your transaction began — they do not see your uncommitted changes. See the ACID & Isolation notes for a full breakdown.

---

## ❓ Practice Questions

1. Write a transaction that simultaneously marks an order as `'Completed'` in the `orders` table and records a bonus in the `performance` table for the employee who handled it. Show both the happy path (COMMIT) and the failure path (ROLLBACK).

2. A developer runs this code:
   ```sql
   UPDATE employees SET salary = 999999 WHERE dept_id = 10;
   -- Realizes the mistake immediately
   ROLLBACK;
   ```
   This fails to undo the change. Why? What should the developer have done differently?

3. Write a transaction with two SAVEPOINTs that: (a) inserts a new customer, (b) creates their first order, (c) applies a discount by updating the order amount. If step (c) fails, roll back only the discount but keep the customer and order. Show the full SQL.

4. In MySQL, what is the difference between:
   - `SET autocommit = 0;` followed by SQL statements
   - `START TRANSACTION;` followed by SQL statements
   
   In which case do you need to explicitly `COMMIT`? What happens in each case if you close the connection without committing?

5. Write a stored procedure (MySQL) called `safe_order_cancel` that takes an `order_id` and: (a) checks if the order status is `'Pending'`, (b) if yes, updates it to `'Cancelled'` inside a transaction, (c) if no, signals an error. Include error handling with ROLLBACK using `DECLARE EXIT HANDLER FOR SQLEXCEPTION`.
