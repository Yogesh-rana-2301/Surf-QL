--  Write your MySQL query statement below
select sample_id,dna_sequence,species,
(case
    when dna_sequence like 'ATG%' then 1
    else 0
    end) as has_start,
(case
    when dna_sequence like '%TAA' then 1
    when dna_sequence like '%TAG' then 1
    when dna_sequence like '%TGA' then 1
    else 0
    end) as has_stop,
(case
    when dna_sequence like '%ATAT%' then 1
    when dna_sequence like '%ATAT' then 1
    when dna_sequence like 'ATAT%' then 1
    else 0 
    end) as has_atat,
(case
    when dna_sequence like '%GGG%' then 1
    when dna_sequence like '%GGG' then 1
    when dna_sequence like 'GGG%' then 1
    else 0
    end) as has_ggg
from Samples;





--  Write your MySQL query statement below
SELECT *, 
    dna_sequence LIKE 'ATG%' AS has_start, 
    (dna_sequence LIKE '%TAA' OR dna_sequence LIKE '%TAG' OR  dna_sequence LIKE '%TGA')   AS has_stop , 
    dna_sequence LIKE '%ATAT%' AS has_atat,
    dna_sequence LIKE '%GGG%' AS has_ggg
FROM Samples 
ORDER BY sample_id;

-- so i think i need is , the like wildcard patterns, %, _







SELECT *, 
FROM Samples
WHERE dna_sequence LIKE 'ATG%'
  AND dna_sequence REGEXP '(TAA|TAG|TGA)$'
  AND dna_sequence LIKE '%ATAT%'
  AND dna_sequence LIKE '%GGG%'
ORDER BY sample_id;

