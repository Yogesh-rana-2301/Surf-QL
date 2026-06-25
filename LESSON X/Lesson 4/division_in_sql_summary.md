# Summary: Division in SQL

## Core idea

SQL does not provide a direct DIVISION operator, but division-like queries are very common.
Division is used when you need entities that are related to all values in another set.

Typical pattern:

- Find x such that x is associated with every required y.
- This is the logical meaning of all.

## When to use division-style queries

- People who have accounts in every bank in a city.
- Students who completed all required courses.
- Suppliers who supply all parts.
- Employees who work on all projects controlled by a department.

## Formal definition

Given relations:

- R(x, y)
- S(y)

R div S returns all distinct x values from R that are associated with every y in S.

Equivalent relational algebra:

R div S = pix(R) - pix((pix(R) x S) - R)

Where pix means projection on x.

## Method 1: Cross Join + EXCEPT

Idea:

1. Build all required pairs of each x with each y in S.
2. Subtract actual pairs in R.
3. Remaining x values are missing at least one y.
4. Final answer is all x minus those missing x values.

Generic query:

```sql
SELECT DISTINCT r1.x
FROM R r1
WHERE r1.x NOT IN (
    SELECT missing.x
    FROM (
        (
            SELECT dx.x, s.y
            FROM (SELECT DISTINCT x FROM R) dx
            CROSS JOIN S s
        )
        EXCEPT
        (
            SELECT x, y
            FROM R
        )
    ) missing
);
```

## Method 2: Correlated subquery with NOT EXISTS

Idea:

- For each candidate x, check that there does not exist any required y missing from R.

Query using EXCEPT inside NOT EXISTS:

```sql
SELECT DISTINCT sx.x
FROM R sx
WHERE NOT EXISTS (
    (SELECT y FROM S)
    EXCEPT
    (SELECT y FROM R sp WHERE sp.x = sx.x)
);
```

Portable alternative (works where EXCEPT is unavailable):

```sql
SELECT DISTINCT sx.x
FROM R sx
WHERE NOT EXISTS (
    SELECT 1
    FROM S s
    WHERE NOT EXISTS (
        SELECT 1
        FROM R sp
        WHERE sp.x = sx.x
          AND sp.y = s.y
    )
);
```

## Relational algebra steps

1. r1 <- pix(R) x S
2. r2x <- pix(r1 - R)
3. result <- pix(R) - r2x

Meaning:

- r2x contains x values that fail at least one required y.
- Subtracting r2x gives x values satisfying all y.

## Practical example 1: Supply schema

Schema:

- supplies(sid, pid)
- parts(pid)

Goal:

- Find suppliers that supply all parts.

Cross Join + EXCEPT:

```sql
SELECT DISTINCT s.sid
FROM supplies s
WHERE s.sid NOT IN (
    SELECT missing.sid
    FROM (
        (
            SELECT ds.sid, p.pid
            FROM (SELECT DISTINCT sid FROM supplies) ds
            CROSS JOIN parts p
        )
        EXCEPT
        (
            SELECT sid, pid
            FROM supplies
        )
    ) missing
);
```

Correlated NOT EXISTS:

```sql
SELECT DISTINCT s.sid
FROM supplies s
WHERE NOT EXISTS (
    (SELECT p.pid FROM parts p)
    EXCEPT
    (SELECT sp.pid FROM supplies sp WHERE sp.sid = s.sid)
);
```

## Practical example 2: Company schema

Goal:

- List employees who work on all projects controlled by department 4.

Correlated NOT EXISTS:

```sql
SELECT e.*
FROM employee e
WHERE NOT EXISTS (
    (SELECT p.pno FROM project p WHERE p.dno = 4)
    EXCEPT
    (SELECT w.pno FROM works_on w WHERE w.essn = e.ssn)
);
```

## More practice prompts

- List suppliers who supply all red parts.
- Find employees who work on all projects that John Smith works on.

## Important points

- SQL has no built-in DIVISION keyword.
- Division is expressed using set difference and universal checks.
- EXCEPT is not available in some engines (for example MySQL); use double NOT EXISTS there.
- Correlated solutions are often easier to read but can be expensive without indexing.
- Add indexes on join/filter columns (for example R(x, y), S(y)) for better scalability.
