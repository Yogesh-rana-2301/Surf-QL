# Summary: SQL ORDER BY Clause

## Core idea

`ORDER BY` sorts query results in ascending (`ASC`) or descending (`DESC`) order.
If no direction is specified, SQL sorts in ascending order by default.

## Main syntax

```sql
SELECT column1, column2, ...
FROM table_name
ORDER BY column_name ASC | DESC;
```

- `table_name`: table to query.
- `column_name`: column used for sorting.
- `ASC`: ascending order (default).
- `DESC`: descending order.

## Basic example

```sql
SELECT EmpID, Name, Department, Salary
FROM Employees
ORDER BY Salary DESC;
```

This sorts employees from highest to lowest salary.

## Common patterns

### 1. Sort by a single column

```sql
SELECT *
FROM students
ORDER BY ROLL_NO DESC;
```

Use `ASC` instead of `DESC` to sort lowest to highest.

### 2. Sort by multiple columns

```sql
SELECT *
FROM students
ORDER BY age DESC, name ASC;
```

Rows are sorted by `age` first. If ages match, they are sorted by `name`.

### 3. Sort by column position number

```sql
SELECT Roll_no, Name, Address
FROM studentinfo
ORDER BY 1;
```

`ORDER BY 1` means sort by the first column in the `SELECT` list (`Roll_no` here).

## Column number syntax

```sql
ORDER BY column_number ASC | DESC;
```

- `column_number` must be greater than `0`.
- `column_number` must not exceed the number of selected columns.

## Best practice note

- Sorting by column name is clearer and easier to maintain.
- Sorting by column number is shorter but less readable.
- Reordering columns in `SELECT` can accidentally change results when using numeric positions.

## Key points

- `ORDER BY` organizes result sets for easier analysis.
- Default sort direction is ascending.
- Multiple sort columns allow tie-breaking.
- Prefer column names over positions in production SQL.
