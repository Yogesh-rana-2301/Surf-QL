# Summary: SQL ALL and ANY Operators

## Core idea

`ALL` and `ANY` compare a value from the outer query against a set of values returned by a subquery.

- `ALL`: condition must be true for every value returned by the subquery.
- `ANY`: condition must be true for at least one value returned by the subquery.

Both are commonly used in `WHERE` and `HAVING` for advanced filtering.

## Main syntax

### ALL

```sql
SELECT column_name(s)
FROM table_name
WHERE expression comparison_operator ALL (
  SELECT column_name
  FROM table_name
  WHERE condition
);
```

### ANY

```sql
SELECT column_name(s)
FROM table_name
WHERE expression comparison_operator ANY (
  SELECT column_name
  FROM table_name
  WHERE condition
);
```

- `comparison_operator`: `=`, `>`, `<`, `>=`, `<=`, `<>`, etc.
- Subquery should return one column of comparable values.

## SQL ALL operator

`ALL` is true only when the comparison matches every returned value.

Example:

```sql
SELECT *
FROM Products
WHERE Price > ALL (
  SELECT Price
  FROM Products
  WHERE Price < 500
);
```

This returns products whose price is greater than all prices under `500`.

### ALL in HAVING

```sql
SELECT OrderID
FROM OrderDetails
GROUP BY OrderID
HAVING MAX(Quantity) > ALL (
  SELECT AVG(Quantity)
  FROM OrderDetails
  GROUP BY OrderID
);
```

This keeps orders where the max quantity is greater than every grouped average quantity.

## SQL ANY operator

`ANY` is true when the comparison matches at least one returned value.

Example:

```sql
SELECT *
FROM Products
WHERE Price < ANY (
  SELECT Price
  FROM Products
  WHERE Price > 500
);
```

This returns products whose price is lower than at least one price above `500`.

### ANY in WHERE

```sql
SELECT ProductName
FROM Products
WHERE ProductID = ANY (
  SELECT ProductID
  FROM OrderDetails
  WHERE Quantity = 9
);
```

This returns product names where at least one related order detail has quantity `9`.

## Note on SELECT ALL

`SELECT ALL column_name` is valid SQL and means return all rows (including duplicates).
It is the default behavior of `SELECT` and is different from the subquery operator `ALL`.

Example:

```sql
SELECT ALL ProductName
FROM Products;
```

## ALL vs ANY

- `ALL` is more restrictive.
- `ANY` is less restrictive.
- `value > ALL (subquery)` means value is greater than every returned value.
- `value > ANY (subquery)` means value is greater than at least one returned value.
- `ALL` usually returns fewer rows.
- `ANY` usually returns more rows.

## Key points

- Use `ALL` when a condition must hold for all values.
- Use `ANY` when matching one qualifying value is enough.
- Keep subqueries single-column and type-compatible with the outer expression.
- `ALL` and `ANY` work well with `WHERE` and `HAVING` for multi-row comparisons.
