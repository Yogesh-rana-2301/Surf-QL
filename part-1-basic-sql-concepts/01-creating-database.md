# 01) Creating Database

A database is a container that holds tables, views, and other objects.
You usually create one database per project or app environment.

## Syntax

```sql
CREATE DATABASE database_name;
```

## Example

```sql
CREATE DATABASE surfql_part1;
```

Use it (MySQL):

```sql
USE surfql_part1;
```

## Safety and Good Practice

- Use lowercase names with underscores for consistency.
- Avoid spaces in database names.
- Use environment-based naming, for example `app_dev`, `app_test`, `app_prod`.

## Common Interview Question

Q: Difference between schema and database?

A:

- In MySQL, people often use these terms loosely.
- In PostgreSQL, one database can contain multiple schemas.
