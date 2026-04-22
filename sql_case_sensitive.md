# SQL Case Sensitivity Guide

## Overview

SQL case sensitivity depends on the context—keywords, identifiers, and data comparisons behave differently across database systems.

---

## 1. SQL Keywords

**Case-sensitive? → No**

All SQL keywords are case-insensitive.

```sql
SELECT * FROM users;
select * from users;
SeLeCt * FrOm users;
```

All of the above queries are equivalent.

---

## 2. Table and Column Names (Identifiers)

**Case-sensitive? → Depends on the database system**

### MySQL

* Case-sensitive on Linux
* Case-insensitive on Windows/macOS (by default)

### PostgreSQL

* Case-insensitive by default
* Case-sensitive when using double quotes

```sql
SELECT name FROM users;      -- same as NAME
SELECT "Name" FROM users;    -- treated differently
```

---

## 3. String Comparisons

**Case-sensitive? → Depends on collation and database**

### MySQL

* Usually case-insensitive

```sql
SELECT * FROM users WHERE name = 'john';  -- matches 'John'
```

### PostgreSQL

* Case-sensitive by default

```sql
SELECT * FROM users WHERE name = 'John';  -- does NOT match 'john'
```

---

## 4. Aliases

* Behave like identifiers
* Case-insensitive by default
* Case-sensitive if quoted

```sql
SELECT name AS Username FROM users;
SELECT name AS "Username" FROM users;
```

---

## Key Takeaways

* SQL keywords are always case-insensitive
* Identifiers depend on database and quoting
* String comparisons depend on collation and database behavior

---

## Interview Insight

In coding interviews and competitive programming:

> Assume SQL keywords are case-insensitive, but identifier and data comparison behavior varies depending on the database system.

---

## Best Practices

* Use consistent casing (prefer uppercase for keywords)
* Avoid quoted identifiers unless necessary
* Be aware of collation settings when comparing strings

---

## Quick Summary Table

| Component          | Case Sensitivity |
| ------------------ | ---------------- |
| SQL Keywords       | No               |
| Table/Column Names | Depends          |
| String Comparisons | Depends          |
| Aliases            | Depends          |

---

End of Guide
