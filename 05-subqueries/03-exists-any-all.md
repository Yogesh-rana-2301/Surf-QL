# EXISTS, ANY & ALL — Set Membership Operators

> **Interview Priority**: 🔴 Must Know

## What Is It?

`EXISTS`, `ANY`, and `ALL` are special operators used with subqueries to perform **set-level comparisons**. Instead of comparing a value against a single scalar, they compare against a *result set* — and each has distinct behaviour around `NULL`, short-circuit evaluation, and performance. These are among the most commonly confused SQL operators in interviews.

---

## Syntax

```sql
-- EXISTS: true if subquery returns at least one row
WHERE EXISTS (SELECT 1 FROM ... WHERE ...)

-- NOT EXISTS: true if subquery returns zero rows
WHERE NOT EXISTS (SELECT 1 FROM ... WHERE ...)

-- IN: true if value matches any value in the list/subquery
WHERE column IN (SELECT col FROM ...)

-- ANY / SOME: true if the comparison holds for at least one value
WHERE column operator ANY (SELECT col FROM ...)

-- ALL: true if the comparison holds for every value
WHERE column operator ALL (SELECT col FROM ...)
```

> `ANY` and `SOME` are synonyms — use whichever reads more naturally.

---

## Key Concepts

### 1 · EXISTS — Existence Check, Not Value Check

`EXISTS` asks: *"Does the subquery return at least one row?"* It **does not care what columns are returned** — only whether any rows exist. That's why `SELECT 1` is conventional inside `EXISTS`; any projection works.

- **Short-circuits**: stops scanning as soon as the first matching row is found.
- Always used as a **correlated subquery** in practice (the inner query references the outer row).
- Returns `TRUE` or `FALSE` — never `NULL`, even if the subquery would return `NULL` values.

### 2 · NOT EXISTS vs NOT IN — The Critical NULL Trap

This is the single most important difference and a favourite interview gotcha:

| Behaviour | `NOT IN` | `NOT EXISTS` |
|-----------|----------|--------------|
| Returns rows when subquery result has a `NULL` | ❌ Returns **nothing** | ✅ Works correctly |
| Returns rows when subquery is empty | ✅ Returns all outer rows | ✅ Returns all outer rows |
| Short-circuits on first match | ❌ | ✅ |
| Safe with NULLs | ❌ | ✅ |

**Why `NOT IN` fails with NULLs:**
SQL evaluates `x NOT IN (1, 2, NULL)` as `x != 1 AND x != 2 AND x != NULL`. Since `x != NULL` is always `UNKNOWN`, the entire expression is `UNKNOWN` — never `TRUE` — so **zero rows pass the filter**.

### 3 · ANY / SOME — At Least One Must Match

`column > ANY (subquery)` is `TRUE` if `column` is greater than *at least one* value in the subquery result. It is equivalent to `column > (SELECT MIN(...))` for `>`, or `column < (SELECT MAX(...))` for `<`.

```sql
-- These are logically identical:
WHERE salary > ANY (SELECT salary FROM employees WHERE dept_id = 20)
WHERE salary > (SELECT MIN(salary) FROM employees WHERE dept_id = 20)
```

### 4 · ALL — Every Value Must Match

`column > ALL (subquery)` is `TRUE` only if `column` is greater than *every* value in the subquery result. Equivalent to `column > (SELECT MAX(...))` for `>`.

```sql
-- These are logically identical:
WHERE salary > ALL (SELECT salary FROM employees WHERE dept_id = 20)
WHERE salary > (SELECT MAX(salary) FROM employees WHERE dept_id = 20)
```

**NULL behaviour in ANY/ALL:**
- If the subquery contains a `NULL`, `ANY` can still be `TRUE` (if another value satisfies the comparison).
- `ALL` with `NULL` in the subquery will be `UNKNOWN` — effectively filtering out the row. Rarely used in production for this reason.

### 5 · IN vs EXISTS — Performance Differences

| Characteristic | `IN` | `EXISTS` |
|----------------|------|----------|
| Evaluates subquery | Fully (materialises the list) | Stops at first match (short-circuits) |
| Best for | Small subquery result sets | Large tables where match is common early |
| NULL safety | Unsafe with `NOT IN` | Safe with `NOT EXISTS` |
| Correlated? | Not required | Usually correlated |
| Index usage | On the subquery column | On the correlated join column |

> Modern query optimisers (MySQL 8+, PostgreSQL, SQL Server) often convert `IN` to a semi-join internally, narrowing the performance gap. But understanding the logical difference still matters.

---

## Examples

### Example 1 — EXISTS: Customers Who Have Placed at Least One Order

```sql
SELECT c.customer_id, c.name, c.city
FROM   customers c
WHERE  EXISTS (
    SELECT 1
    FROM   orders o
    WHERE  o.customer_id = c.customer_id   -- correlated
);
```

For each customer row, the engine checks whether a matching row exists in `orders`. The moment it finds one, it marks the customer as `TRUE` and moves on — no need to count all orders.

---

### Example 2 — NOT EXISTS: Customers Who Have Never Ordered

```sql
SELECT c.customer_id, c.name
FROM   customers c
WHERE  NOT EXISTS (
    SELECT 1
    FROM   orders o
    WHERE  o.customer_id = c.customer_id
);
```

Compare to `NOT IN` — both look correct, but:

```sql
-- DANGEROUS version — if any customer_id in orders is NULL, this returns nothing
SELECT c.name
FROM   customers c
WHERE  c.customer_id NOT IN (
    SELECT o.customer_id FROM orders o
);

-- SAFE version
SELECT c.name
FROM   customers c
WHERE  NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

---

### Example 3 — EXISTS with a Condition: Customers Who Have a 'Delivered' Order

```sql
SELECT c.name
FROM   customers c
WHERE  EXISTS (
    SELECT 1
    FROM   orders o
    WHERE  o.customer_id = c.customer_id
      AND  o.status = 'Delivered'
);
```

You can add any conditions inside `EXISTS` — it is a full `SELECT` statement with access to the outer alias.

---

### Example 4 — ANY: Products Priced Higher Than Any Food Item

```sql
-- Returns products more expensive than the cheapest food product
SELECT product_name, price, category
FROM   products
WHERE  price > ANY (
    SELECT price
    FROM   products
    WHERE  category = 'Food'
);
```

This returns all products whose price exceeds **at least one** Food product's price. If the cheapest Food item costs 5.00, any product priced above 5.00 qualifies.

---

### Example 5 — ALL: Products Priced Higher Than Every Food Item

```sql
-- Returns products more expensive than the MOST EXPENSIVE food product
SELECT product_name, price, category
FROM   products
WHERE  price > ALL (
    SELECT price
    FROM   products
    WHERE  category = 'Food'
);
```

Only products whose price exceeds **every** Food product's price appear — effectively those priced above the maximum Food price.

---

### Example 6 — IN vs EXISTS Side-by-Side (Same Result)

```sql
-- Using IN
SELECT name
FROM   customers
WHERE  customer_id IN (
    SELECT customer_id
    FROM   orders
    WHERE  status = 'Pending'
);

-- Using EXISTS (preferred for large orders table)
SELECT c.name
FROM   customers c
WHERE  EXISTS (
    SELECT 1
    FROM   orders o
    WHERE  o.customer_id = c.customer_id
      AND  o.status = 'Pending'
);
```

Both return the same customers, but `EXISTS` short-circuits per customer and does not materialise the full pending orders list.

---

### Example 7 — ALL with Comparison: Orders Larger Than All Orders From a Specific Customer

```sql
-- Orders with amount greater than every order placed by customer_id = 5
SELECT order_id, amount, customer_id
FROM   orders
WHERE  amount > ALL (
    SELECT amount
    FROM   orders
    WHERE  customer_id = 5
);
```

---

## EXISTS vs IN vs NOT EXISTS vs NOT IN — Decision Guide

```
Need to check existence only?
    → EXISTS (forward check) / NOT EXISTS (inverse check) — always safe

Need to match against a known small list?
    → IN ('Delivered', 'Shipped', 'Pending') — clean and readable

Subquery result might contain NULLs?
    → Avoid NOT IN, use NOT EXISTS

Need "at least one" comparison with an operator other than =?
    → ANY

Need "all values" comparison?
    → ALL (but watch out for NULLs in subquery)
```

---

## Interview Tips

1. **The `NOT IN` NULL trap is the most common interview question on this topic.** Prepare a concrete example showing why `NOT IN` returns zero rows when the subquery has even one `NULL`. Always recommend `NOT EXISTS` as the safe alternative.

2. **`EXISTS` does not care about SELECT columns.** A common misconception is that `SELECT *` inside `EXISTS` affects performance. It does not — the engine only checks row existence. `SELECT 1`, `SELECT NULL`, `SELECT *` all behave identically inside `EXISTS`.

3. **`= ANY` is equivalent to `IN`.** When the operator is `=`, `ANY` and `IN` behave identically. Interviewers sometimes ask this to check depth of knowledge.

4. **`!= ALL` is equivalent to `NOT IN` (with the same NULL caveat).** `x != ALL (subquery)` means x is not equal to any value — same trap applies if subquery returns `NULL`.

5. **EXISTS vs IN on performance.** While modern optimisers narrow the gap, the conceptual answer is: `EXISTS` short-circuits on first match (good when the inner table is large and matches are common); `IN` materialises the full subquery result first (good when the subquery is small and result can be cached). Always mention that the real answer depends on the query plan — check `EXPLAIN`.

---

## ❓ Practice Questions

1. Write a query using `EXISTS` to find all **customers who have placed at least one order with `status = 'Shipped'`**.

2. Using `NOT EXISTS`, find all **products that have never appeared in any order**. Why is `NOT EXISTS` safer than `NOT IN` for this query?

3. Write a query using `ANY` to find **employees whose salary is greater than at least one employee in the Marketing department** (dept_id = 40).

4. Using `ALL`, find **orders whose amount is greater than every order placed in the month of January 2024**. What does the result look like if no January 2024 orders exist?

5. A junior developer wrote the following query and complains it returns no rows even though they know some customers have no orders. Diagnose the bug and rewrite it correctly:
   ```sql
   SELECT name FROM customers
   WHERE customer_id NOT IN (
       SELECT customer_id FROM orders
   );
   ```
   *(Hint: think about what happens if `customer_id` can be NULL in `orders`.)*
