# Summary: SQL USING Clause

## Core idea

The `USING` clause simplifies joins when two tables share one or more columns with the same name.
It removes the need to write full join conditions for those common columns.

## Why use USING

- Makes join syntax shorter and cleaner.
- Avoids repetitive column qualification in join conditions.
- Improves readability in multi-table queries.
- Works with `INNER JOIN`, `LEFT JOIN`, and `RIGHT JOIN`.

## Main syntax

```sql
SELECT column_list
FROM table1
JOIN table2
USING (common_column);
```

You can also use multiple shared columns:

```sql
... USING (col1, col2)
```

## Example 1: Employee working locations

```sql
SELECT e.EMPLOYEE_ID, e.LAST_NAME, d.LOCATION_ID
FROM Employees e
JOIN Departments d
USING (DEPARTMENT_ID);
```

Explanation:

- `Employees` and `Departments` are joined on shared column `DEPARTMENT_ID`.
- The query returns employee ID, last name, and the department location ID.

Sample output:

```text
EMPLOYEE_ID | LAST_NAME | LOCATION_ID
100         | King      | 1700
101         | Kochhar   | 1700
102         | De Haan   | 1700
```

## Example 2: Location and country details

```sql
SELECT l.location_id, l.street_address, l.postal_code, c.country_name
FROM locations l
JOIN countries c
USING (country_id);
```

Explanation:

- `locations` and `countries` are joined by `country_id`.
- It returns address details with matching country name.

Sample output:

```text
location_id | street_address   | postal_code | country_name
1000        | 1297 Via Cola di | 00989       | Italy
1100        | 93091 Calle della| 10934       | Italy
1200        | 2017 Shinjuku-ku | 1689        | Japan
```

## Common mistakes

### 1) Qualifying the column inside USING

Incorrect:

```sql
SELECT e.EMPLOYEE_ID, e.LAST_NAME, d.LOCATION_ID
FROM Employees e
JOIN Departments d
USING (d.DEPARTMENT_ID);
```

Correct:

```sql
SELECT e.EMPLOYEE_ID, e.LAST_NAME, d.LOCATION_ID
FROM Employees e
JOIN Departments d
USING (DEPARTMENT_ID);
```

Reason:
Inside `USING (...)`, write only the column name, not table alias or table name.

### 2) Referring to joined column incorrectly in WHERE

Incorrect:

```sql
SELECT l.location_id, l.street_address, l.postal_code, c.country_name
FROM locations l
JOIN countries c
USING (country_id)
WHERE c.country_id = 'IT';
```

Correct:

```sql
SELECT l.location_id, l.street_address, l.postal_code, c.country_name
FROM locations l
JOIN countries c
USING (country_id)
WHERE country_id = 'IT';
```

Reason:
The `USING` column is treated as a single merged column in the join result.

## USING vs ON (quick note)

- Use `USING` when join columns have the same name in both tables.
- Use `ON` when column names differ, or when conditions are more complex.

## Key points

- `USING` reduces redundancy in join statements.
- It improves readability when tables share identically named key columns.
- Keep `USING` columns unqualified.
- Prefer `ON` when you need custom or non-equality join logic.
