# Write your MySQL query statement below
WITH cnt AS (
    SELECT query_name,COUNT(*) AS cnt1
    FROM Queries
    GROUP BY query_name
),
a AS (
    SELECT q.query_name, ROUND(((SUM(q.rating/q.position))/cnt1),2) AS quality
    FROM Queries AS q
    JOIN cnt
        ON cnt.query_name= q.query_name
    GROUP BY q.query_name
), 
b AS (
    SELECT q.query_name ,
       ROUND(SUM(CASE WHEN rating < 3 THEN 1 ELSE 0 END)/ cnt1*100,2)  AS poor_query_percentage
    FROM Queries AS q 
    JOIN cnt
        ON cnt.query_name= q.query_name
    GROUP BY q.query_name
)
SELECT a.query_name, a.quality, b.poor_query_percentage
FROM a 
JOIN b
    ON a.query_name=b.query_name
/*
*/




# Write your MySQL query statement below
select q.query_name, 
Round(SUM(q.rating/q.position) / count(*) ,2) as quality , 
ROUND(AVG(q.rating<3)*100 ,2) as poor_query_percentage 
from Queries q
group by q.query_name ;
