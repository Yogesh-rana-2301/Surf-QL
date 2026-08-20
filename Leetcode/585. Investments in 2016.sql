# Write your MySQL query statement below
SELECT ROUND(SUM(tiv_2016), 2) AS tiv_2016
FROM Insurance
WHERE tiv_2015 IN (
    SELECT tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(*) > 1
)
AND (lat, lon) IN (
    SELECT lat, lon
    FROM Insurance
    GROUP BY lat, lon
    HAVING COUNT(*) = 1
)




# Write your MySQL query statement below
SELECT ROUND(SUM(tiv_2016),2) AS tiv_2016
FROM
(SELECT pid , tiv_2016 , 
COUNT(*)OVER (PARTITION BY tiv_2015) AS tiv_2015_count , 
COUNT(*)OVER (PARTITION BY lat , lon) AS location_count
FROM Insurance ) AS t1
WHERE tiv_2015_count > 1 
AND location_count = 1 
