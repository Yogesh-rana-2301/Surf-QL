# Summary: SQL LIKE Operator

## Core idea

The `LIKE` operator is used to search text by pattern instead of exact match.

It is commonly used with wildcard characters for flexible filtering.

## Wildcards used with LIKE

- `%` matches zero or more characters.
- `_` matches exactly one character.
- `[]` matches one character from a set (mainly SQL Server style).
- `-` defines ranges inside `[]` (for example `[a-z]`, SQL Server style).

## Main syntax

```sql
SELECT column1, column2, ...
FROM table_name
WHERE column_name LIKE pattern;
```

```sql
SELECT column1, column2, ...
FROM table_name
WHERE column_name NOT LIKE pattern;
```

## Common pattern meanings

- `'a%'` : starts with `a`
- `'%a'` : ends with `a`
- `'a%t'` : starts with `a` and ends with `t`
- `'%wow%'` : contains `wow` anywhere
- `'_wow%'` : `wow` starts at second position
- `'_a%'` : `a` is at second position
- `'a__%'` : starts with `a` and has at least two more characters

## Example patterns

- Names starting with `Ca`:

```sql
SELECT SupplierID, Name, Address
FROM Supplier
WHERE Name LIKE 'Ca%';
```

- Addresses containing `Kungsgatan`:

```sql
SELECT *
FROM Supplier
WHERE Address LIKE '%Kungsgatan%';
```

- Names where `afe` starts from second position:

```sql
SELECT SupplierID, Name, Address
FROM Supplier
WHERE Name LIKE '_afe%';
```

- Suppliers from Madrid with names starting with `C`:

```sql
SELECT SupplierID, Name, Address
FROM Supplier
WHERE Address LIKE '%Madrid%'
  AND Name LIKE 'C%';
```

- Names not containing `Co`:

```sql
SELECT SupplierID, Name, Address
FROM Supplier
WHERE Name NOT LIKE '%Co%';
```

## Case sensitivity note

Case sensitivity with `LIKE` depends on database collation and engine behavior:

- PostgreSQL: use `ILIKE` for case-insensitive matching.
- MySQL: behavior depends on collation; use case-sensitive collation or `BINARY` when needed.
- SQL Server: behavior depends on selected collation.

## Key points

- `LIKE` is for pattern matching in text columns.
- `NOT LIKE` excludes matching patterns.
- `%` and `_` are the most portable wildcards across databases.
- Bracket wildcards (`[]`) are not universal across all SQL dialects.
