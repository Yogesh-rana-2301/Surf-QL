# Write your MySQL query statement below
select *
FROM Cinema
where description <> 'boring'
group by id
having id%2!=0

ORDER BY rating DESC;








# Write your MySQL query statement below
SELECT id, movie, description, rating
FROM Cinema
WHERE description <> "boring" AND id%2!=0
ORDER BY rating DESC
; 
