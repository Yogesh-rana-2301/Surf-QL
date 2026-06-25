# Summary: SQL CASE Statement

## Core idea

The `CASE` statement adds conditional logic inside SQL queries.

It evaluates conditions in order and returns the first matching result, similar to IF-THEN-ELSE.

## Main syntax

- Simple CASE (compare one expression to fixed values):

```sql
CASE case_value
  WHEN value1 THEN result1
  WHEN value2 THEN result2
  ELSE default_result
END
```

- Searched CASE (evaluate boolean conditions):

```sql
CASE
  WHEN condition1 THEN result1
  WHEN condition2 THEN result2
  ELSE default_result
END
```

## Common use cases

- Categorize values into labels (for example age groups).
- Transform output values in `SELECT`.
- Apply conditional sorting in `ORDER BY`.
- Apply conditional updates in `UPDATE` statements.

## Example patterns

- Age grouping with simple CASE:

```sql
SELECT CustomerID, CustomerName, Age,
       CASE Age
         WHEN 21 THEN 'Young Adult'
         WHEN 22 THEN 'Adult'
         WHEN 23 THEN 'Mid Adult'
         WHEN 24 THEN 'Senior Adult'
         ELSE 'Unknown'
       END AS AgeGroup
FROM Customer;
```

- Nationality mapping with searched CASE:

```sql
SELECT CustomerName, Country, Age,
       CASE
         WHEN Country = 'United Kingdom' THEN 'British'
         WHEN Country = 'Australia' THEN 'Australian'
         WHEN Country = 'Japan' THEN 'Japanese'
         WHEN Country = 'Austria' THEN 'Austrian'
         WHEN Country = 'Spain' THEN 'Spanish'
         ELSE 'Other'
       END AS Nationality
FROM Customer;
```

- Multiple age conditions:

```sql
SELECT CustomerName, Age,
       CASE
         WHEN Age = 21 THEN 'Age is 21'
         WHEN Age = 22 THEN 'Age is 22'
         WHEN Age > 22 THEN 'Age is greater than 22'
         ELSE 'Age is below 21'
       END AS AgeDescription
FROM Customer;
```

- CASE with ORDER BY:

```sql
SELECT
  CustomerName,
  Country,
  CASE
    WHEN Country = 'Japan' THEN 0
    ELSE 1
  END AS SortPriority
FROM Customer
ORDER BY SortPriority, Country;
```

## Key points

- `CASE` returns the first match only.
- If no `WHEN` condition matches, `ELSE` value is returned.
- If `ELSE` is omitted and no condition matches, result is `NULL`.
- `CASE` can be used in `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, and `UPDATE`.
