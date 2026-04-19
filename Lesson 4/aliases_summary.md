# Summary: SQL Aliases

## Core idea

Aliases in SQL provide temporary names for columns or tables inside a query.
They make queries cleaner, shorter, and easier to understand.

## Why aliases are useful

- Improve readability in long queries.
- Rename output columns for reports.
- Simplify joins by shortening table names.
- Help when the same table is used multiple times (self-join).

## Types of aliases

There are two common types:

1. Column aliases
2. Table aliases

## 1) Column aliases

A column alias renames a column only in the query output.

Main syntax:

```sql
SELECT column_name AS alias_name
FROM table_name;
```

Notes:

- `AS` is optional in SQL.
- Alias name exists only for that query result.

Example:

```sql
SELECT EmpID AS id
FROM Employees;
```

Sample output:

```text
id
101
102
103
```

Explanation:
This query fetches `EmpID` from `Employees` and shows it under temporary column name `id`.

Another example:

```sql
SELECT CustomerID AS id
FROM Customer;
```

Sample output:

```text
id
1
2
3
```

## 2) Table aliases

A table alias gives a temporary short name to a table during query execution.
It is especially useful in joins.

Main syntax:

```sql
SELECT t.column_name
FROM table_name AS t;
```

Self-join example with table aliases:

```sql
SELECT c1.CustomerName, c1.Country
FROM Customer AS c1, Customer AS c2
WHERE c1.Age = c2.Age
  AND c1.Country = c2.Country
  AND c1.CustomerID <> c2.CustomerID;
```

Sample output:

```text
CustomerName | Country
Aarav        | India
Meera        | India
```

Explanation:
The same `Customer` table is referenced twice using `c1` and `c2`.
The query finds customers who share the same age and country.

## Combining column and table aliases

```sql
SELECT c.CustomerName AS Name, c.Country AS Location
FROM Customer AS c
WHERE c.Age >= 21;
```

Sample output:

```text
Name   | Location
Aarav  | India
Riya   | USA
Karan  | India
```

Explanation:
`c` is a table alias for `Customer`.
`Name` and `Location` are column aliases used only in output.

## Key points

- Aliases are temporary and query-scoped.
- `AS` keyword is optional in most SQL dialects.
- Column aliases improve result clarity.
- Table aliases make joins and self-joins easier to write and read.
