-- Write your MySQL query statement below
SELECT p.firstName,p.lastName,a.city,a.state
FROM Person p
LEFT JOIN Address a
ON p.personId=a.personId;


-- Write your MySQL query statement below
SELECT P.firstName, P.lastName, A.city, A.state
  
FROM Person as P 
LEFT OUTER JOIN Address as A
USING (personId);


-- what it is asking me for is , firstname and lastname from person table, city and state from adedress , so i know i need to do joins, and left outer 
