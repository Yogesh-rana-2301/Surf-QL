# MySQL Data Types (Complete Guide)

## 🔷 1. Numeric Data Types

### 📌 Integers

* `TINYINT` (1 byte)
* `SMALLINT` (2 bytes)
* `MEDIUMINT` (3 bytes)
* `INT` / `INTEGER` (4 bytes)
* `BIGINT` (8 bytes)

**Use Case:** IDs, counters, indexing

---

### 📌 Floating Point (Approximate)

* `FLOAT`
* `DOUBLE`

**Use Case:** Scientific calculations (not for money)

---

### 📌 Fixed Point (Exact Precision)

* `DECIMAL(M, D)`

```sql
price DECIMAL(10,2)  -- Example: 12345678.90
```

**Use Case:** Financial data (high precision)

---

### 📌 Boolean

* `BOOLEAN` (internally stored as `TINYINT(1)`)

---

## 🔷 2. String Data Types

### 📌 Fixed Length

* `CHAR(n)`

---

### 📌 Variable Length

* `VARCHAR(n)`

**Most commonly used string type**

---

### 📌 Text Types

* `TINYTEXT`
* `TEXT`
* `MEDIUMTEXT`
* `LONGTEXT`

**Use Case:** Large text (articles, descriptions)

---

### 📌 Binary Strings

* `BINARY`
* `VARBINARY`
* `BLOB` (TINYBLOB → LONGBLOB)

**Use Case:** Images, files, raw bytes

---

### 📌 ENUM & SET

* `ENUM('A','B','C')` → single value
* `SET('A','B','C')` → multiple values

---

## 🔷 3. Date & Time Data Types

* `DATE` → YYYY-MM-DD
* `TIME` → HH:MM:SS
* `DATETIME` → date + time
* `TIMESTAMP` → auto time tracking (timezone aware)
* `YEAR`

**Use Case:**

* `TIMESTAMP` → logs, system tracking
* `DATETIME` → user input

---

## 🔷 4. Spatial Data Types

* `GEOMETRY`
* `POINT`
* `LINESTRING`
* `POLYGON`

**Use Case:** Maps, GPS, geolocation systems

---

## 🔷 5. JSON Type

* `JSON`

```sql
data JSON
```

**Use Case:** Semi-structured data storage

---

## 🔷 6. Special Types

* `NULL` → absence of value

---

# 🔥 Key Interview Insights

### ✅ VARCHAR vs TEXT

* `VARCHAR` → faster, indexable
* `TEXT` → for large data, slower

### ✅ DATETIME vs TIMESTAMP

* `TIMESTAMP` → timezone aware, auto updates
* `DATETIME` → static value

### ✅ FLOAT/DOUBLE vs DECIMAL

* `FLOAT/DOUBLE` → fast but imprecise
* `DECIMAL` → precise (use for money)

---

# ⚡ Final Summary

* **Numbers** → `INT`, `BIGINT`, `DECIMAL`
* **Text** → `VARCHAR`, `TEXT`
* **Time** → `DATETIME`, `TIMESTAMP`
* **Restricted values** → `ENUM`
* **Complex data** → `JSON`

---

# 🧠 Tip

In real-world system design:

* Prefer `VARCHAR` over `TEXT` unless needed
* Use `BIGINT` for scalable systems (IDs can overflow INT)
* Always use `DECIMAL` for financial applications
