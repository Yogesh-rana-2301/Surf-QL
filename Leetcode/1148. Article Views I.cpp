# Write your MySQL query statement below
select distinct author_id as id
from VIEWS
where author_id=viewer_id
order by id asc;
