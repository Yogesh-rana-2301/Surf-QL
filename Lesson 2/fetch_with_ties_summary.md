# Summary: FETCH FIRST ... WITH TIES (Oracle 12c)

## Core idea

`FETCH FIRST n ROWS ONLY` returns exactly `n` rows after sorting.

`FETCH FIRST n ROWS WITH TIES` also returns any extra rows that are tied with the last returned row based on the `ORDER BY` values.

This solves a common ranking problem where strict row limits can hide valid tied results.

## Main syntax

```sql
SELECT column_name(s)
FROM table_name
ORDER BY sort_column [ASC|DESC]
FETCH FIRST n ROWS ONLY;
```

```sql
SELECT column_name(s)
FROM table_name
ORDER BY sort_column [ASC|DESC]
FETCH FIRST n ROWS WITH TIES;
```

## Common use cases

- Show top performers while including tied scores.
- Build fair leaderboard outputs.
- Return ranked results without cutting off equal values.
- Create user-facing reports where ties must be visible.

## Example patterns

Given table `myTable`:

- `ID`
- `NAME`
- `SALARY`

Example data includes multiple employees with `SALARY = 10000`.

- First 3 rows by highest salary (strict limit):

```sql
SELECT *
FROM myTable
ORDER BY Salary DESC
FETCH FIRST 3 ROWS ONLY;
```

- First 3 rows by highest salary, including ties:

```sql
SELECT *
FROM myTable
ORDER BY Salary DESC
FETCH FIRST 3 ROWS WITH TIES;
```

In this case, rows tied on the 3rd row salary are also returned.

## Key points

- `WITH TIES` is available in Oracle Database 12c+.
- `WITH TIES` is meaningful only with `ORDER BY` because ties are based on sort values.
- `ONLY` always returns exactly the requested number of rows (unless fewer rows exist).
- `WITH TIES` can return more than `n` rows when ties exist at the boundary.
- This behavior is useful in real-world ranking scenarios (for example, tied race positions or equal scores).
