# Summary: EXISTS Operator in SQL

## Core idea

`EXISTS` checks whether a subquery returns at least one row.

- Returns `TRUE` if the subquery has rows.
- Returns `FALSE` if the subquery returns no rows.
- Commonly used with correlated subqueries.

## Main syntax

```sql
SELECT column_name(s)
FROM table_name t
WHERE EXISTS (
  SELECT 1
  FROM other_table o
  WHERE o.related_id = t.id
);
```

```sql
SELECT column_name(s)
FROM table_name t
WHERE NOT EXISTS (
  SELECT 1
  FROM other_table o
  WHERE o.related_id = t.id
);
```

## Common use cases

- Return parent rows that have related child rows.
- Return rows that do not have related records (`NOT EXISTS`).
- Filter rows in `DELETE` and `UPDATE` using related-table conditions.
- Handle existence checks without returning extra columns.

## Example patterns

- Customers who placed at least one order:

```sql
SELECT c.Name
FROM Customers c
WHERE EXISTS (
  SELECT 1
  FROM Orders o
  WHERE o.CustomerID = c.CustomerID
);
```

- Customers who have not placed any order:

```sql
SELECT c.lname, c.fname
FROM Customers c
WHERE NOT EXISTS (
  SELECT 1
  FROM Orders o
  WHERE o.CustomerID = c.customer_id
);
```

- Delete orders for customers whose website is `abc.com`:

```sql
DELETE FROM Orders o
WHERE EXISTS (
  SELECT 1
  FROM Customers c
  WHERE c.customer_id = o.CustomerID
    AND c.website = 'abc.com'
);
```

- Update a customer row using EXISTS condition:

```sql
UPDATE Customers c
SET lname = 'Martin'
WHERE EXISTS (
  SELECT 1
  FROM Customers c2
  WHERE c2.customer_id = 401
    AND c2.customer_id = c.customer_id
);
```

## EXISTS vs IN

- `EXISTS` checks whether at least one matching row exists.
- `IN` checks whether a value is in a returned list/set.
- `EXISTS` often performs better on large correlated datasets because it can stop after the first match.
- `IN` is often clearer for small fixed lists or simple subqueries.
- `NOT EXISTS` is generally safer than `NOT IN` when `NULL` values are possible.

## Key points

- Use `SELECT 1` inside `EXISTS` for clarity.
- `EXISTS` focuses on row existence, not returned column values.
- Correlated conditions are usually required for meaningful filtering.
- `NOT EXISTS` is a common pattern for finding missing relationships.
