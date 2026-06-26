# CREATE DATABASE — Your SQL Workspace Container

> **Interview Priority**: 🟡 Important

## What Is It?

A **database** is a named container that groups related tables, views, indexes, and other objects together. Think of it like a folder — before you can create any table, you must first create (or select) a database to hold it. In MySQL and most RDBMS systems, you switch between databases to scope all subsequent operations.

## Syntax

```sql
-- Create a new database
CREATE DATABASE database_name;

-- Create only if it doesn't already exist (safe, no error)
CREATE DATABASE IF NOT EXISTS database_name;

-- Select a database to use for subsequent queries
USE database_name;

-- List all databases on the server
SHOW DATABASES;

-- Remove a database and ALL its tables/data (irreversible)
DROP DATABASE database_name;

-- Drop only if it exists (safe, no error)
DROP DATABASE IF EXISTS database_name;
```

## Key Concepts

- **Databases are containers**: Tables, views, stored procedures, and indexes all live inside a database. Without selecting one, your SQL engine doesn't know where to look.
- **`IF NOT EXISTS` is production-safe**: Running `CREATE DATABASE` twice without `IF NOT EXISTS` throws an error. The guard clause makes scripts idempotent (safe to re-run).
- **`USE` scopes all statements**: After `USE surfql;`, every `SELECT`, `INSERT`, and `DROP TABLE` operates inside `surfql` unless you prefix with `other_db.table_name`.
- **`DROP DATABASE` is permanent**: It deletes all tables and data inside the database without confirmation. Always back up first.
- **Database names are case-sensitive on Linux**: `SurfQL` and `surfql` are different databases on Linux MySQL but the same on Windows/macOS. Always use consistent lowercase names.
- **Character set matters**: Specify character set to handle Unicode properly: `CREATE DATABASE surfql CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`

## Examples

```sql
-- Step 1: Create the SurfQL training database
CREATE DATABASE IF NOT EXISTS surfql;

-- Step 2: Select it
USE surfql;

-- Step 3: Verify it exists
SHOW DATABASES;
-- Output includes: surfql

-- Step 4: Create with explicit charset (best practice for apps storing names/emojis)
CREATE DATABASE IF NOT EXISTS surfql
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Step 5: Cross-database query (without USE)
SELECT * FROM surfql.employees;

-- Step 6: Drop the database (DO NOT run unless you mean it)
DROP DATABASE IF EXISTS surfql;
```

```sql
-- Real-world pattern: setup script header
DROP DATABASE IF EXISTS surfql;
CREATE DATABASE surfql CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE surfql;
-- ... CREATE TABLE statements follow ...
```

## Interview Tips

1. **`IF NOT EXISTS` is not optional in scripts**: Interviewers ask why setup scripts use `IF NOT EXISTS`. Answer: makes the script idempotent — safe to run multiple times without throwing errors.

2. **Difference between `DROP` and `TRUNCATE`**: `DROP DATABASE` removes the entire database including structure. `TRUNCATE TABLE` removes only rows, keeping the table. `DROP TABLE` removes one table. Know the hierarchy.

3. **`USE` vs fully-qualified names**: `USE surfql` sets a default context. But you can always write `surfql.employees` to access a table from a different database in the same query — useful in cross-database joins.

4. **`SHOW DATABASES` privilege**: In a production server, non-admin users may not see all databases — only those they have access to. This is controlled via GRANT.

5. **Character set in interviews**: If asked "how do you support emojis or Hindi text in MySQL?", the answer always involves `utf8mb4` charset, not just `utf8` (which is only 3 bytes in MySQL and can't store 4-byte emoji characters).

## ❓ Practice Questions

1. Write a SQL script that safely creates a database called `surfql`, selects it, and verifies it appears in the database list. Make the script safe to run multiple times.

``` sql
DROP DATABASE IF EXISTS db;
CREATE DATABASE db;
USE db;
SHOW DATABASES;

```

3. You are setting up a new MySQL server for a company. Write the commands to create a database named `company_db` with proper Unicode support, then make it the active database.
``` sql
DROP DATABASE IF EXISTS company_db;
CREATE DATABASE company_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE company_db;


```

4. What is the difference between `DROP DATABASE surfql` and `DROP TABLE employees`? What happens to the data in each case?

6. A junior developer runs `CREATE DATABASE surfql;` twice on the same server and gets an error on the second run. What change would you make to the command to prevent this, and why?
``` sql
DROP DATABASE IF EXISTS company_db;
```

8. You need to query the `employees` table in `surfql` and the `users` table in `auth_db` in the same SQL statement without using `USE`. Write the query.

``` sql
SELECT * from surfql.employess;

SELECT * from auth_db.users;


```
