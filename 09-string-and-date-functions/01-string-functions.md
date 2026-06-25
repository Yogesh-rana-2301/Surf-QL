# String Functions — Manipulating Text Data in SQL

> **Interview Priority**: 🔴 Must Know

## What Is It?

String functions let you manipulate, format, search, and transform text values directly inside SQL queries. They're heavily used in interview problems involving cleaning data, extracting parts of a string (e.g., email domain), and formatting output for reports.

---

## Syntax

Each function has its own syntax — see individual sections below. General pattern:

```sql
SELECT STRING_FUNCTION(column, [arguments]) FROM table;
```

---

## Key Concepts

- Most string functions are **not case-sensitive by default** for matching, but functions like `UPPER`/`LOWER` change the actual value.
- String indexing in SQL is **1-based** (first character is position 1).
- `NULL` propagates through most string functions — `CONCAT('a', NULL)` returns `NULL` in MySQL but `'a'` in PostgreSQL.
- Dialect matters: MySQL uses `SUBSTRING`, PostgreSQL uses `SUBSTRING` or `SUBSTR`; SQL Server uses `CHARINDEX` instead of `INSTR`.
- `COALESCE` is one of the most practically important functions for handling NULLs in output.

---

## Examples

### 1. CONCAT / CONCAT_WS — Join strings together

`CONCAT` joins strings. `CONCAT_WS` (Concat With Separator) inserts a separator between each value and **skips NULLs automatically**.

```sql
-- Full name from separate columns (employees only has 'name', so we'll split for illustration)
SELECT CONCAT('Employee: ', name) AS label
FROM employees;
-- Result: "Employee: Aman", "Employee: Priya", ...

-- CONCAT_WS: great for building formatted strings
SELECT CONCAT_WS(' | ', name, email, dept_id) AS employee_info
FROM employees;
-- Result: "Aman | aman@company.com | 10"

-- MySQL quirk: CONCAT returns NULL if ANY argument is NULL
SELECT CONCAT(name, NULL) FROM employees;  -- returns NULL for every row

-- PostgreSQL / CONCAT_WS are safer with NULLs
SELECT CONCAT_WS(', ', name, NULL, email) FROM employees;
-- NULL is silently skipped → "Aman, aman@company.com"
```

> **Dialect note**: SQL Server uses `+` operator: `name + ' ' + email`. PostgreSQL also supports `||`.

---

### 2. LENGTH / CHAR_LENGTH — Count characters

`LENGTH` returns the byte length (matters for multibyte/unicode). `CHAR_LENGTH` returns the character count (safer for international text).

```sql
-- How long is each employee's name?
SELECT name, CHAR_LENGTH(name) AS name_length
FROM employees
ORDER BY name_length DESC;

-- Find employees with unusually long email addresses
SELECT name, email, LENGTH(email) AS email_len
FROM employees
WHERE LENGTH(email) > 25;
```

> **Dialect note**: PostgreSQL uses `LENGTH()` for character count. SQL Server uses `LEN()` (trims trailing spaces) or `DATALENGTH()` (byte count).

---

### 3. UPPER / LOWER — Change case

```sql
-- Normalize names to uppercase for comparison
SELECT UPPER(name) AS upper_name, LOWER(email) AS lower_email
FROM employees;
-- Result: "AMAN", "aman@company.com"

-- Case-insensitive search using LOWER
SELECT * FROM employees
WHERE LOWER(email) LIKE '%@engineering.com';

-- Standardize department names before joining
SELECT e.name, UPPER(d.dept_name) AS department
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```

---

### 4. TRIM / LTRIM / RTRIM — Remove whitespace (or characters)

`TRIM` removes both leading and trailing spaces. `LTRIM` removes left-side only, `RTRIM` removes right-side only.

```sql
-- Clean up messy data
SELECT TRIM(name) AS clean_name FROM employees;

-- Remove only leading spaces
SELECT LTRIM('   Aman') AS result;  -- 'Aman'

-- Remove only trailing spaces
SELECT RTRIM('Priya   ') AS result;  -- 'Priya'

-- MySQL/PostgreSQL: TRIM can also remove specific characters
SELECT TRIM(LEADING '0' FROM '00042') AS result;  -- '42'
SELECT TRIM(BOTH '#' FROM '###hello###') AS result; -- 'hello'
```

> **Dialect note**: SQL Server has `TRIM()` from 2017+. Before that, use `LTRIM(RTRIM(column))`.

---

### 5. SUBSTRING / SUBSTR / LEFT / RIGHT — Extract part of a string

`SUBSTRING(str, start, length)` — extracts from position `start` for `length` characters.  
`LEFT(str, n)` — first n characters.  
`RIGHT(str, n)` — last n characters.

```sql
-- Extract first 3 characters of employee name
SELECT name, LEFT(name, 3) AS short_name
FROM employees;
-- Aman → Ama, Priya → Pri

-- Extract last 4 characters (e.g., year from a string date)
SELECT RIGHT('hire_2019', 4) AS year_part;  -- '2019'

-- SUBSTRING: extract domain from email
-- email format: user@domain.com
SELECT
    name,
    email,
    SUBSTRING(email, INSTR(email, '@') + 1) AS email_domain
FROM employees;
-- aman@company.com → company.com

-- SUBSTRING with fixed positions
SELECT SUBSTRING('2024-06-15', 1, 4) AS year_part;  -- '2024'
SELECT SUBSTRING('2024-06-15', 6, 2) AS month_part; -- '06'
```

> **Dialect note**:  
> - MySQL: `SUBSTRING(str, pos, len)` or `SUBSTR(str, pos, len)` — identical  
> - PostgreSQL: `SUBSTRING(str FROM pos FOR len)` or `SUBSTR(str, pos, len)`  
> - SQL Server: `SUBSTRING(str, pos, len)` — same as MySQL

---

### 6. REPLACE — Substitute part of a string

`REPLACE(string, old_substring, new_substring)`

```sql
-- Mask part of email for display
SELECT name, REPLACE(email, SUBSTRING(email, 1, INSTR(email,'@')-1), '***') AS masked_email
FROM employees;
-- aman@company.com → ***@company.com

-- Replace domain in bulk (e.g., company rebranding)
UPDATE employees
SET email = REPLACE(email, '@oldcompany.com', '@newcompany.com');

-- Remove hyphens from a string
SELECT REPLACE('2024-06-15', '-', '') AS compact_date;  -- '20240615'
```

---

### 7. INSTR / POSITION / LOCATE — Find position of a substring

Returns the **1-based position** of a substring within a string. Returns `0` if not found.

```sql
-- Find the position of '@' in email
SELECT name, email, INSTR(email, '@') AS at_position
FROM employees;
-- aman@company.com → 5

-- POSITION is ANSI SQL (works in MySQL and PostgreSQL)
SELECT POSITION('@' IN email) AS at_position FROM employees;

-- LOCATE(substr, str) — MySQL specific, same result
SELECT LOCATE('@', email) AS at_position FROM employees;

-- Use INSTR to extract username from email
SELECT name,
       LEFT(email, INSTR(email, '@') - 1) AS username
FROM employees;
-- aman@company.com → aman
```

> **Dialect note**: SQL Server uses `CHARINDEX(substr, str)`. PostgreSQL uses `POSITION(substr IN str)` or `STRPOS(str, substr)`.

---

### 8. LPAD / RPAD — Pad a string to a target length

`LPAD(str, length, pad_string)` — pad on the left.  
`RPAD(str, length, pad_string)` — pad on the right.

```sql
-- Format emp_id as zero-padded 5-digit string
SELECT name, LPAD(emp_id, 5, '0') AS formatted_id
FROM employees;
-- emp_id=3 → '00003'

-- Right-pad product names to fixed width for display
SELECT RPAD(name, 20, '.') AS formatted_name FROM employees;
-- 'Aman................'

-- Useful for generating report codes
SELECT CONCAT('EMP-', LPAD(emp_id, 4, '0')) AS employee_code
FROM employees;
-- EMP-0001, EMP-0002, ...
```

> **Dialect note**: `LPAD`/`RPAD` are available in MySQL and PostgreSQL. SQL Server does not have them natively — use `RIGHT('00000' + CAST(emp_id AS VARCHAR), 5)` as a workaround.

---

### 9. COALESCE — Handle NULLs in output ⭐ Very Important

`COALESCE(val1, val2, ..., valN)` returns the **first non-NULL value** in the list. This is ANSI SQL and works everywhere.

```sql
-- Show 'No Manager' if manager_id is NULL (top-level employees)
SELECT name,
       COALESCE(CAST(manager_id AS CHAR), 'No Manager') AS manager_display
FROM employees;

-- Use COALESCE to provide a fallback email
SELECT name,
       COALESCE(email, 'no-email@unknown.com') AS contact_email
FROM employees;

-- Combine with string functions: show bonus or 'N/A' if NULL
SELECT e.name,
       COALESCE(CAST(p.bonus AS CHAR), 'N/A') AS bonus_display
FROM employees e
LEFT JOIN performance p ON e.emp_id = p.emp_id AND p.year = 2023;

-- COALESCE with multiple fallbacks
SELECT COALESCE(NULL, NULL, 'third', 'fourth');  -- returns 'third'
```

> **Why COALESCE beats IFNULL/NVL**: `COALESCE` is ANSI SQL and accepts **multiple arguments**. `IFNULL` (MySQL) and `NVL` (Oracle) only take two arguments.

---

### 10. NULLIF — Return NULL when two values are equal

`NULLIF(expr1, expr2)` returns `NULL` if `expr1 = expr2`, otherwise returns `expr1`. Useful for avoiding division-by-zero errors.

```sql
-- Avoid division by zero when calculating per-employee averages
SELECT
    dept_id,
    SUM(salary) / NULLIF(COUNT(*), 0) AS avg_salary
FROM employees
GROUP BY dept_id;

-- Treat empty string the same as NULL
SELECT NULLIF(TRIM(name), '') AS clean_name
FROM employees;
-- If name = '   ', TRIM gives '', NULLIF converts '' to NULL

-- Use with COALESCE to chain: return meaningful default
SELECT COALESCE(NULLIF(TRIM(email), ''), 'unknown@na.com') AS safe_email
FROM employees;
```

---

## Common Interview String Problems

### Problem 1: Extract Domain from Email

```sql
-- Get the domain part after '@'
SELECT
    name,
    email,
    SUBSTRING(email, INSTR(email, '@') + 1) AS domain
FROM employees;
-- aman@company.com → company.com

-- PostgreSQL version using SPLIT_PART
SELECT
    name,
    SPLIT_PART(email, '@', 2) AS domain
FROM employees;
```

---

### Problem 2: Capitalize First Letter of Name

MySQL does not have `INITCAP` (PostgreSQL does). In MySQL:

```sql
-- MySQL: Capitalize first letter manually
SELECT
    name,
    CONCAT(
        UPPER(LEFT(name, 1)),
        LOWER(SUBSTRING(name, 2))
    ) AS capitalized_name
FROM employees;
-- 'aman' → 'Aman'

-- PostgreSQL: use INITCAP
SELECT INITCAP(name) AS capitalized_name FROM employees;
```

---

### Problem 3: Count Occurrences of a Character in a String

SQL has no built-in `COUNT_OCCURRENCES`. Classic trick: compare lengths.

```sql
-- Count how many dots are in each email address
SELECT
    name,
    email,
    (CHAR_LENGTH(email) - CHAR_LENGTH(REPLACE(email, '.', ''))) AS dot_count
FROM employees;
-- aman.k@company.co.in → 3 dots

-- Count how many times 'a' appears in name
SELECT
    name,
    (CHAR_LENGTH(LOWER(name)) - CHAR_LENGTH(REPLACE(LOWER(name), 'a', ''))) AS count_a
FROM employees;
```

---

### Problem 4: Reverse a String

```sql
SELECT name, REVERSE(name) AS reversed_name FROM employees;
-- MySQL and SQL Server support REVERSE()
-- PostgreSQL: SELECT REVERSE(name) FROM employees; -- also works
```

---

### Problem 5: Check if a String Is a Palindrome

```sql
-- Find employees whose name reads the same forwards and backwards
SELECT name FROM employees
WHERE LOWER(name) = LOWER(REVERSE(name));
```

---

## Dialect Differences Summary

| Function | MySQL | PostgreSQL | SQL Server |
|---|---|---|---|
| String concat | `CONCAT()` or `||` | `\|\|` or `CONCAT()` | `+` or `CONCAT()` |
| Substring | `SUBSTRING(s, pos, len)` | `SUBSTRING(s FROM pos FOR len)` | `SUBSTRING(s, pos, len)` |
| Find position | `INSTR(s, sub)` | `STRPOS(s, sub)` | `CHARINDEX(sub, s)` |
| String length | `CHAR_LENGTH()` | `LENGTH()` | `LEN()` |
| Pad left | `LPAD(s, n, pad)` | `LPAD(s, n, pad)` | No native; use RIGHT |
| Capitalize | No INITCAP; manual | `INITCAP()` | No native |
| Split by delimiter | No SPLIT_PART | `SPLIT_PART(s, delim, n)` | `STRING_SPLIT()` (table-valued) |
| Null-safe concat | `CONCAT_WS()` | `CONCAT_WS()` | `CONCAT_WS()` (2017+) |

---

## Interview Tips

1. **COALESCE is everywhere** — Always use `COALESCE` over `IFNULL`/`NVL` in interviews. It works across all dialects and handles multiple fallbacks.

2. **String indexing is 1-based** — A common mistake is starting `SUBSTRING` at position 0. In SQL, position 1 is the first character (position 0 often behaves like 1 in MySQL but is technically wrong).

3. **NULLIF for division-by-zero** — If asked "how do you avoid division by zero?", answer with `NULLIF(denominator, 0)` — it's clean and impressive.

4. **Email parsing is a classic question** — Know how to extract the username and domain using `INSTR` + `LEFT`/`SUBSTRING`. Practice this cold.

5. **REPLACE for counting occurrences** — The trick `LENGTH(str) - LENGTH(REPLACE(str, char, ''))` is a very common interview problem. The interviewer wants to see if you know this workaround since SQL has no native count-occurrences function.

6. **Dialect awareness matters** — Mentioning that `INSTR` is MySQL-specific while `POSITION` is ANSI SQL signals that you've worked across databases.

---

## ❓ Practice Questions

1. Write a query to display each employee's **username** (the part of email before `@`) and **email domain** (the part after `@`) as separate columns.

2. Write a query to find all employees whose **name contains the letter 'a'** (case-insensitive), and display their name length alongside. Order by name length descending.

3. Write a query that formats each employee's record as a single string in the format: `"EMP-0001 | Aman | Engineering"` — zero-padded ID, name, and department name. (Hint: join with departments, use `LPAD` and `CONCAT_WS`.)

4. The `manager_id` column is NULL for top-level employees. Write a query listing all employees with a column `reports_to` showing their manager's name — or the text `'Top Level'` if they have no manager. (Hint: self-join + COALESCE.)

5. Write a query to count how many employees have an email address containing **more than one dot** (`.`), using only string functions (no regex). Show their name, email, and dot count.
