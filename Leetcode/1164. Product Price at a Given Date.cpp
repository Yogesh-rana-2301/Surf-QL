WITH latest AS (
    SELECT product_id, new_price,
           ROW_NUMBER() OVER (
               PARTITION BY product_id
               ORDER BY change_date DESC
           ) AS rn
    FROM Products
    WHERE change_date <= '2019-08-16'
),
products AS (
    SELECT DISTINCT product_id
    FROM Products
)
SELECT p.product_id,
       IFNULL(l.new_price, 10) AS price
FROM products p
LEFT JOIN latest l
    ON p.product_id = l.product_id
   AND l.rn = 1;
