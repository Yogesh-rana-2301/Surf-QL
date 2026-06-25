# Summary: CREATE DATABASE

## Core idea

`CREATE DATABASE` creates a new, empty database container where tables and other objects will be stored.

## Main syntax

```sql
CREATE DATABASE database_name;
```

Safer version:

```sql
CREATE DATABASE IF NOT EXISTS database_name;
```

## Related commands

```sql
SHOW DATABASES;
USE database_name;
DROP DATABASE database_name;
```

## Key points

- Database names should not contain spaces (use underscores if needed).
- `USE` selects the active database context for next operations.
- `DROP DATABASE` permanently removes the database and all its data.
