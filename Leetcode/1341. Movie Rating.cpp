(SELECT u.name AS results
    FROM Users u
    INNER JOIN MovieRating mr
    ON u.user_id=mr.user_id
    GROUP BY u.user_id,u.name
    ORDER BY COUNT(*) DESC,u.name
    LIMIT 1
)
UNION ALL
(   SELECT m.title AS results
    FROM Movies m
    INNER JOIN MovieRating mr
    ON m.movie_id=mr.movie_id
    WHERE mr.created_at LIKE '2020-02%'
    GROUP BY m.movie_id,m.title
    ORDER BY AVG(mr.rating) DESC,m.title 
    LIMIT 1
)
