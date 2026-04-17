# Summary: SQL Wildcard Characters

## Core idea

SQL wildcard characters are special symbols used for pattern matching in text values.

They are mostly used with `LIKE` and `NOT LIKE` to search flexible patterns instead of exact text.

## Wildcards covered

- `%` matches zero or more characters.
- `_` matches exactly one character.
- `[abc]` matches one character from a set (dialect-specific).
- `[a-z]` matches one character in a range (dialect-specific).
- `[^abc]` or `[!abc]` matches one character not in the set (dialect-specific).

## Main syntax

```sql
SELECT column1, column2
FROM table_name
WHERE column_name LIKE 'pattern';
```

```sql
SELECT column1, column2
FROM table_name
WHERE column_name NOT LIKE 'pattern';
```

## Common use cases

- Find names starting with, ending with, or containing certain letters.
- Match fixed-length text patterns.
- Filter values that do not match a pattern.
- Build search boxes and partial-match filters in apps.

## Example patterns

- Starts with A:

```sql
SELECT *
FROM Customer
WHERE CustomerName LIKE 'A%';
```

- Ends with l:

```sql
SELECT *
FROM Customer
WHERE CustomerName LIKE '%l';
```

- Contains A anywhere:

```sql
SELECT *
FROM Customer
WHERE CustomerName LIKE '%A%';
```

- Country contains ra:

```sql
SELECT DISTINCT *
FROM Customer
WHERE Country LIKE '%ra%';
```

- Exactly 7 characters:

```sql
SELECT *
FROM Customer
WHERE Country LIKE '_______';
```

- Starts with Dan and has exactly 3 extra characters:

```sql
SELECT *
FROM Customer
WHERE CustomerName LIKE 'Dan___';
```

- Combined pattern (starts with 8, then any two chars, then 5, then anything):

```sql
SELECT *
FROM Student
WHERE Phone LIKE '8__5%';
```

## Dialect note

Bracket patterns such as `[A-C]` are commonly supported in SQL Server `LIKE` patterns. In MySQL and PostgreSQL, use regular expression functions/operators for character classes (for example `REGEXP` in MySQL or regex operators in PostgreSQL).

## Key points

- `%` is for variable-length matching.
- `_` is for single-character matching.
- `LIKE` matches a pattern; `NOT LIKE` excludes a pattern.
- Pattern behavior can differ by SQL dialect, especially for bracket expressions.
