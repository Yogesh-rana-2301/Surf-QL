SQL doesn’t run top → bottom. It runs like this:

1. FROM
2. WHERE ✅ (row filtering happens here)
3. GROUP BY
4. HAVING ✅ (group filtering happens here)
5. SELECT
6. ORDER BY

---

---

WHERE cannot use aggregate functions

```sql
SELECT department, COUNT(*)
FROM employees
WHERE COUNT(*) > 5   ❌ ERROR
GROUP BY department;
```

```sql
SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 5;
```

---

---

WHERE → filters before grouping

```sql
SELECT name, salary
FROM employees
WHERE salary > 50000;
```

HAVING → filters after grouping

```sql
SELECT department, COUNT(*) AS total
FROM employees
GROUP BY department
HAVING COUNT(*) > 5;
```
