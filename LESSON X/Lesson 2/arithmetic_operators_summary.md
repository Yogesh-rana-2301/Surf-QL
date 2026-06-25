# Summary: Arithmetic Operators in SQL

## Core idea

Arithmetic operators in SQL perform mathematical calculations on numeric data directly in queries.

They are commonly used to calculate totals, differences, percentages, and transformed values.

## Operators covered

- Addition: `+`
- Subtraction: `-`
- Multiplication: `*`
- Division: `/`
- Modulus (remainder): `%`

## Main syntax

```sql
SELECT
  column1,
  column2,
  column1 + 100 AS plus_example,
  column1 - 100 AS minus_example,
  column1 * 100 AS multiply_example,
  column1 / 100 AS divide_example,
  column1 % 100 AS modulus_example
FROM table_name;
```

## Common use cases

- Column with constant: `salary + 100`
- Column with another column: `salary + employee_id`
- Derived metrics in reports and dashboards
- Even/odd checks and remainder-based logic using `%`

## Example patterns

- Addition with constant:

```sql
SELECT employee_id, employee_name, salary,
       salary + 100 AS salary_plus_100
FROM addition;
```

- Subtraction with column:

```sql
SELECT employee_id, employee_name, salary,
       salary - employee_id AS salary_minus_employee_id
FROM subtraction;
```

- Multiplication with constant:

```sql
SELECT employee_id, employee_name, salary,
       salary * 100 AS salary_times_100
FROM addition;
```

- Division example:

```sql
SELECT employee_id, employee_name, salary,
       salary / 100 AS salary_div_100
FROM addition;
```

- Modulus with constant:

```sql
SELECT employee_id, employee_name, salary,
       salary % 25000 AS salary_mod_25000
FROM addition;
```

## NULL behavior

If any operand is `NULL`, the arithmetic result is `NULL`.

```sql
SELECT employee_id, employee_name, salary, type,
       type + 100 AS type_plus_100
FROM addition;
```

## Key points

- Arithmetic can be applied to one column, multiple columns, or constants.
- `NULL` means unknown, so arithmetic with `NULL` returns `NULL`.
- Division behavior (integer vs decimal result) can vary by SQL dialect.
- Avoid divide-by-zero errors by validating divisor values first.
