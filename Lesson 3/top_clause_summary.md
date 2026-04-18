# Summary: SQL Server TOP Clause

## Core idea

The `TOP` clause in Microsoft SQL Server limits the number of rows returned by a query.
It is useful when working with large datasets because it fetches only a required subset of rows.

## Main syntax

```sql
SELECT TOP value column1, column2
FROM table_name;
```

## Syntax with percentage

```sql
SELECT TOP value PERCENT column1, column2
FROM table_name;
```

`TOP ... PERCENT` returns a percentage of total rows instead of a fixed row count.

## Demo table setup

```sql
CREATE TABLE Customer(
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    LastName VARCHAR(50),
    Country VARCHAR(50),
    Age INT,
    Phone VARCHAR(20)
);

INSERT INTO Customer (CustomerID, CustomerName, LastName, Country, Age, Phone)
VALUES
    (1, 'Shubham', 'Thakur', 'India', 23, 'xxxxxxxxxx'),
    (2, 'Aman', 'Chopra', 'Australia', 21, 'xxxxxxxxxx'),
    (3, 'Naveen', 'Tulasi', 'Sri Lanka', 24, 'xxxxxxxxxx'),
    (4, 'Aditya', 'Arpan', 'Austria', 21, 'xxxxxxxxxx'),
    (5, 'Nishant', 'Jain', 'Spain', 22, 'xxxxxxxxxx');
```

## Common examples

### 1. Fetch first 2 rows

```sql
SELECT TOP 2 *
FROM Customer;
```

### 2. Use TOP with WHERE

```sql
SELECT TOP 1 *
FROM Customer
WHERE Country = 'Spain';
```

This returns one row that matches the condition.

### 3. Use TOP PERCENT

```sql
SELECT TOP 40 PERCENT *
FROM Customer;
```

If the table has 5 rows, this returns 2 rows (40% of 5).

## Cross-database note

Equivalent pattern in MySQL:

```sql
SELECT column1, column2
FROM table_name
LIMIT value;
```

## Key points

- `TOP` is specific to SQL Server style querying.
- Use `TOP n` for a fixed number of rows.
- Use `TOP n PERCENT` for percentage-based row limits.
- Combine `TOP` with `WHERE` to limit filtered results.
- For deterministic results, pair `TOP` with `ORDER BY`.
