SELECT p.product_id,
       ROUND(
           COALESCE(SUM(p.price * u.units) / NULLIF(SUM(u.units), 0), 0),
           2
       ) AS average_price
FROM Prices p
LEFT JOIN UnitsSold u
    ON p.product_id = u.product_id
    AND u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY p.product_id;








# Write your MySQL query statement below
WITH cte AS (
    SELECT p.product_id, COALESCE(p.price * u.units,0) AS total_price, COALESCE(u.units ,0)AS units
    FROM Prices AS p
    LEFT JOIN UnitsSold AS u
        ON u.product_id = p.product_id
        AND u.purchase_date BETWEEN p.start_date AND p.end_date
)
SELECT product_id, COALESCE(ROUND(SUM(COALESCE(total_price, 0))/SUM(COALESCE(units, 0)),2),0) AS average_price
FROM cte as c
GROUP BY product_id
;
