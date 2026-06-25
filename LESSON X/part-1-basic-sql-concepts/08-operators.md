# 08) Operators

Operators help combine or compare conditions in SQL.
These are heavily used inside `WHERE`.

## Logical Operators

### AND

All conditions must be true.

```sql
SELECT *
FROM students
WHERE city = 'Pune' AND age >= 20;
```

### OR

At least one condition must be true.

```sql
SELECT *
FROM students
WHERE city = 'Pune' OR city = 'Mumbai';
```

### NOT

Negates a condition.

```sql
SELECT *
FROM students
WHERE NOT city = 'Delhi';
```

## Comparison Operators

- `=` equal
- `!=` or `<>` not equal
- `>` greater than
- `<` less than
- `>=` greater than or equal
- `<=` less than or equal

```sql
SELECT *
FROM students
WHERE age >= 21;
```

## Other Useful Operators

### IN

```sql
SELECT *
FROM students
WHERE city IN ('Delhi', 'Mumbai');
```

### BETWEEN

```sql
SELECT *
FROM students
WHERE age BETWEEN 19 AND 21;
```

### LIKE

```sql
SELECT *
FROM students
WHERE student_name LIKE 'A%';
```

## Operator Precedence

`AND` is evaluated before `OR`.
Use parentheses for clarity.

```sql
SELECT *
FROM students
WHERE (city = 'Delhi' OR city = 'Mumbai') AND age >= 20;
```
