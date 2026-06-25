# LIKE & Wildcards — Pattern Matching in SQL

> **Interview Priority**: 🔴 Must Know

## What Is It?

`LIKE` is a SQL operator used in `WHERE` clauses to match string values against a **pattern** containing wildcard characters. It is the standard way to do partial string matching without a full-text search engine. `ILIKE` (PostgreSQL) is its case-insensitive variant.

## Syntax

```sql
SELECT columns
FROM table
WHERE column LIKE 'pattern';

-- Negation
WHERE column NOT LIKE 'pattern';

-- Case-insensitive (PostgreSQL)
WHERE column ILIKE 'pattern';

-- Escape a wildcard character literally
WHERE column LIKE '50\%' ESCAPE '\';
```

## Key Concepts

### Wildcard Characters

| Wildcard | Meaning | Example Pattern | Matches |
|---|---|---|---|
| `%` | Zero or more of *any* characters | `'A%'` | `'Aman'`, `'Alex'`, `'A'` |
| `%` | Zero or more of *any* characters | `'%a'` | `'Priya'`, `'Zara'`, `'Nina'` |
| `%` | Zero or more of *any* characters | `'%av%'` | `'Ravi'`, `'David'` |
| `_` | Exactly **one** of any character | `'_avi'` | `'Ravi'` but NOT `'Davi'` (4 chars only) |
| `_` | Exactly **one** of any character | `'R__i'` | `'Ravi'`, `'Romi'` (exactly 4 chars, starts R, ends i) |

- **`%` (percent)**: Matches zero, one, or many characters. Think of it as `.*` in regex.
- **`_` (underscore)**: Matches exactly one character. Think of it as `.` in regex.
- Both wildcards are case-sensitive with `LIKE` (in most collations) and case-insensitive with `ILIKE`.

### Additional Rules

- **ILIKE** is PostgreSQL-specific. In MySQL, `LIKE` is case-insensitive by default for most collations (`utf8_general_ci`). In SQL Server use `LIKE` with a `CI` collation or `LOWER()` on both sides.
- **NOT LIKE** returns rows where the column does *not* match the pattern — and also **excludes NULLs** (because `NULL LIKE 'X'` is `NULL`, not `TRUE` or `FALSE`).
- **ESCAPE clause**: When the pattern itself must contain a literal `%` or `_`, define an escape character (e.g., `ESCAPE '!'`) and prefix the wildcard with it: `'50!%'`.
- **Performance**: `LIKE 'A%'` (prefix search) can use a B-tree index. `LIKE '%avi%'` (infix/suffix) cannot — it forces a full table scan. Use full-text indexes for infix searches at scale.
- **SIMILAR TO** (PostgreSQL) is a more powerful pattern operator supporting POSIX-style regex; `REGEXP`/`RLIKE` (MySQL) allows full regular expressions.

## Examples

### 1 — Employee names starting with 'A'

```sql
SELECT name, email
FROM employees
WHERE name LIKE 'A%';

-- Matches: Aman
```

### 2 — Employee names ending with 'a'

```sql
SELECT name
FROM employees
WHERE name LIKE '%a';

-- Matches: Priya, Zara
```

### 3 — Employee names containing 'av'

```sql
SELECT name
FROM employees
WHERE name LIKE '%av%';

-- Matches: Ravi, Dev  (Dev has no 'av' — only 'Ravi' matches here)
-- Actually: Ravi contains 'av', Dev does not → only Ravi
```

### 4 — Exactly 4-character names

```sql
SELECT name
FROM employees
WHERE name LIKE '____';   -- four underscores

-- Matches: Aman (4), Ravi (4), Zara (4)
-- Does NOT match: Priya (5), Dev (3)
```

### 5 — Names where second character is 'a'

```sql
SELECT name
FROM employees
WHERE name LIKE '_a%';

-- Matches: Ravi (R-a-v-i), Zara (Z-a-r-a)
```

### 6 — Email addresses from a specific domain

```sql
SELECT name, email
FROM employees
WHERE email LIKE '%@company.com';

-- Matches every employee with a company.com email
```

### 7 — Email addresses starting with 'a' or 'r' (combine with OR)

```sql
SELECT name, email
FROM employees
WHERE email LIKE 'a%'
   OR email LIKE 'r%';

-- Matches: aman@..., ravi@...
```

### 8 — NOT LIKE — employees whose name does NOT start with 'A'

```sql
SELECT name
FROM employees
WHERE name NOT LIKE 'A%';

-- Returns: Priya, Ravi, Zara, Dev
-- Note: if name were NULL, that row would also be excluded
```

### 9 — Case-insensitive search with ILIKE (PostgreSQL)

```sql
-- Matches 'Aman', 'aman', 'AMAN', 'aMan' etc.
SELECT name
FROM employees
WHERE name ILIKE 'aman';
```

### 10 — Case-insensitive in MySQL (use LOWER)

```sql
SELECT name
FROM employees
WHERE LOWER(name) LIKE 'aman';
```

### 11 — Searching for a literal underscore in product_name

```sql
-- product_name contains 'USB_Type_C' — need to match literal underscores
SELECT product_name
FROM products
WHERE product_name LIKE '%USB!_Type!_C%' ESCAPE '!';
```

### 12 — Pattern matching on customer city

```sql
-- Cities that start with 'New'
SELECT name, city
FROM customers
WHERE city LIKE 'New%';

-- Cities with exactly 6 characters
SELECT name, city
FROM customers
WHERE city LIKE '______';   -- 6 underscores
```

## Pattern Quick-Reference Table

| Pattern | Meaning | Matches | Does NOT Match |
|---|---|---|---|
| `'A%'` | Starts with A | `Aman`, `Alex`, `A` | `aman`, `Priya` |
| `'%a'` | Ends with a | `Priya`, `Zara` | `Aman`, `Ravi` |
| `'%av%'` | Contains av | `Ravi`, `David` | `Dev`, `Aman` |
| `'____'` | Exactly 4 chars | `Aman`, `Ravi`, `Zara` | `Priya`, `Dev` |
| `'_a%'` | 2nd char is a | `Ravi`, `Zara` | `Aman`, `Dev` |
| `'R_vi'` | R, any 1 char, vi | `Ravi` | `Rovi1`, `Rav` |
| `'%@%.com'` | Email-like pattern | `x@y.com` | `x@y.org` |

## Interview Tips

1. **`LIKE '%term%'` cannot use a regular B-tree index** — the leading `%` prevents index range scans. Interviewers may ask how you'd optimise this; answer with full-text indexes (`FULLTEXT` in MySQL, `GIN/GIST` in PostgreSQL) or a search engine.
2. **`_` vs `%`**: Be precise — `_` is *exactly one character*, not "one or more". A common mistake is using `_` when `%` is meant.
3. **NULL behaviour**: `NULL LIKE '%'` evaluates to `NULL` (not `TRUE`). So `NOT LIKE` silently drops NULL rows. Always check if NULLs are relevant.
4. **`ILIKE` is PostgreSQL-only**: In MySQL `LIKE` is case-insensitive for most default collations. In SQL Server use `COLLATE` or `LOWER()`. Knowing the cross-DB difference impresses interviewers.
5. **Escape characters**: If asked "how do you search for a literal `%` in a string?", answer with the `ESCAPE` clause — e.g., `LIKE '100\%' ESCAPE '\'` to find the string `100%`.

## ❓ Practice Questions

1. Write a query to find all employees whose `name` starts with the letter **'P'** or ends with the letter **'i'** (use `LIKE` with `OR`).

2. Find all customers whose `email` contains the domain `gmail.com`. Show `name` and `email`.

3. Write a query to retrieve all products where the `product_name` contains exactly **two words** separated by a space (Hint: `LIKE '% %'` — but also think about why this isn't perfect and what edge cases exist).

4. Find all employees whose `name` is exactly **4 characters long** and whose name ends with **'vi'**.

5. Write a query that finds all orders where the `status` column does **NOT** start with the word `'Complete'`. Make sure your answer also correctly handles any rows where `status` might be `NULL` (add an explicit `IS NULL` check and explain why).
