# Write your MySQL query statement below
WITH cte AS (
    SELECT student_id, subject_name, COUNT(*) AS CNT
    FROM Examinations
    GROUP BY student_id, subject_name
)
SELECT a.student_id , a.student_name, b.subject_name , COALESCE(c.CNT,0) AS attended_exams
FROM Students AS a
CROSS JOIN subjects AS b
LEFT JOIN cte AS c
    ON a.student_id = c.student_id 
    AND b.subject_name = c.subject_name
ORDER BY student_id, subject_name 
; 
/*




*/
