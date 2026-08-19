# Write your MySQL query statement below
SELECT patient_id, patient_name, conditions
FROM Patients
WHERE conditions LIKE 'DIAB1%' OR conditions LIKE '% DIAB1%'
; 



# Write your MySQL query statement below
select *
from Patients
where instr(conditions," DIAB1") !=0 or instr(conditions,"DIAB1") =1
order by patient_id
