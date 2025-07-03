--Netflix Project
--Create Database netflix_db;

-- Analysis
select * from netflix;

select 
Count(*)
from netflix;

select DISTINCT type from netflix


-- 15 Business Problems & Solutions
--1. Count the number of Movies vs TV Shows
SELECT 
    type, 
    COUNT(*) AS Total_Value
FROM 
    netflix
GROUP BY 
    type;

--2. Find the most common rating for movies and TV shows
Select
    type,
    rating
from
(
    SELECT 
        type, 
        rating, 
        COUNT(*) AS Count,
        RANK() OVER(Partition by type order by COUNT(*) DESC) as ranking
    FROM 
        netflix
    GROUP BY 
        type, rating
) as t1
where ranking = 1;

--3. List all movies released in a specific year (e.g., 2020)
SELECT 
    *
FROM 
    netflix
WHERE 
    type = 'Movie' AND 
    release_year = 2020;

--4. Find the top 5 countries with the most content on Netflix
WITH SplitCountries AS (
    SELECT 
        CAST(LEFT(country, CHARINDEX(',', country + ',') - 1) AS NVARCHAR(MAX)) AS Country,
        STUFF(country, 1, CHARINDEX(',', country + ','), '') AS Remaining
    FROM 
        netflix
    WHERE 
        country IS NOT NULL
    UNION ALL
    SELECT 
        CAST(LEFT(Remaining, CHARINDEX(',', Remaining + ',') - 1) AS NVARCHAR(MAX)),
        STUFF(Remaining, 1, CHARINDEX(',', Remaining + ','), '')
    FROM 
        SplitCountries
    WHERE 
        Remaining <> ''
)
SELECT 
TOP 5
    TRIM(Country) AS New_Countries,
    COUNT(*) AS total_value
FROM 
    SplitCountries
GROUP BY 
    TRIM(Country)
ORDER BY 
    total_value DESC;

--5. Identify the longest movie or TV show duration

--First Approach
SELECT
    --TOP 1
    --title, 
    --duration
    *
FROM 
    netflix
where type = 'Movie'
ORDER BY 
    CAST(SUBSTRING(duration, 1, LEN(duration) - 4) AS INT) DESC;


--6. Find content added in the last 4 years
SELECT 
     *
FROM 
    netflix
WHERE 
    DATEADD(YEAR, -4, GETDATE()) <= DATEADD(DAY, 0, date_added);

--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT 
    *
FROM 
    netflix
WHERE 
    director Like '%Rajiv Chilaka%';

--8. List all TV shows with more than 5 seasons
SELECT 
    * 
FROM 
    netflix
WHERE 
    type = 'TV Show' AND 
    CAST(SUBSTRING(duration, 1, LEN(duration) - (Len(duration)-1)) AS INT) > 5;

--9. Count the number of content items in each genre

SELECT 
    value AS Genre,
    COUNT(show_id) AS Total_content
FROM 
    netflix
CROSS APPLY 
    STRING_SPLIT(listed_in, ',')
Group By value;

--10. Find the average release year for content produced in a specific country
SELECT 
    value as Country, 
    AVG(release_year) AS Average_Release_Year
FROM 
    netflix
CROSS APPLY 
    STRING_SPLIT(country, ',')
GROUP BY 
    value;

--11. Find each year and the average numbers of content release by South Korea on Netflix.
--    return top 5 year with highest avg content release!
--First Approach
SELECT TOP 5
    r_year,
    content_count AS content_yealy_count,
    ROUND((AVG(content_count) * 100.0 / total_content.total_count), 2) AS average_percentage
FROM (
    SELECT
        YEAR(date_added) AS r_year,
        COUNT(*) AS content_count
    FROM
        netflix
    WHERE
        country LIKE '%South Korea%'
        AND YEAR(date_added) IS NOT NULL
    GROUP BY
        YEAR(date_added)
) AS subquery
CROSS JOIN (
    SELECT COUNT(*) AS total_count
    FROM netflix
    WHERE country LIKE '%South Korea%'
) AS total_content
GROUP BY
    r_year, total_content.total_count
ORDER BY
    content_yealy_count DESC;

--Second Approach
SELECT TOP 5
        YEAR(date_added) AS r_year,
        COUNT(*) AS content_count,
        ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) AS total_count
                                        FROM netflix
                                        WHERE country LIKE '%South Korea%')), 2) AS average_percentage
    FROM
        netflix
    WHERE
        country LIKE '%South Korea%'
        AND YEAR(date_added) IS NOT NULL
    GROUP BY
        YEAR(date_added)
    ORDER BY
    average_percentage DESC;

--12. List all movies that are documentaries
SELECT 
    * 
FROM 
    netflix
WHERE 
    listed_in LIKE '%documentaries%';

--13. Find all content without a director
SELECT 
    * 
FROM 
    netflix
WHERE 
    director IS NULL OR director = '';

--14. Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT
    *
FROM 
    netflix
WHERE 
    casts LIKE '%Salman Khan%' AND 
    release_year >= YEAR(GETDATE()) - 10 AND 
    type = 'Movie';

--15. Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT TOP 10
    Value as Actor,
    COUNT(*) AS Movie_Count
FROM 
    netflix
 CROSS APPLY 
    STRING_SPLIT(casts, ',')
WHERE 
    type = 'Movie'
    AND country LIKE '%India%'
    AND casts is not null
GROUP BY 
    value
ORDER BY 
    Movie_Count DESC;

--16. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field.
--	Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category..
SELECT 
    CASE 
        WHEN description LIKE 'kill%' OR description LIKE '%violence%' THEN 'Bad'
        ELSE 'Good'
    END AS Content_Category,
    COUNT(*) AS total_content
FROM 
    netflix
GROUP BY 
    CASE 
        WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad'
        ELSE 'Good'
    END;

--17. Count the Number of Unique Directors
SELECT 
    COUNT(DISTINCT value) AS Unique_Directors
FROM 
    netflix
CROSS APPLY
    STRING_SPLIT(director, ',')
Where director is not null;

--18. Find the Most Prolific Director
SELECT TOP 1
    value as Director, 
    COUNT(*) AS Title_Count
FROM 
    netflix
CROSS APPLY
    STRING_SPLIT(director, ',')
Where 
    director is not null
GROUP BY 
    value
ORDER BY 
    Title_Count DESC;

--19. List All Countries with Content in a Specific Genre
-- Which countries have content in the genre 'Action & Adventure'?
SELECT 
    DISTINCT value as Country 
FROM 
    netflix
CROSS APPLY
    STRING_SPLIT(country, ',')
WHERE 
    listed_in LIKE '%Action & Adventure%'
    AND country is not null;


-- 20. Find the top genre for each rating
WITH GenreCount AS (
    SELECT 
        t.rating,
        TRIM(value) AS listed_in,
        COUNT(*) AS Genre_Count
    FROM 
        netflix t
    CROSS APPLY 
        STRING_SPLIT(t.listed_in, ',') AS SplitGenres
    WHERE 
        t.type = 'TV Show' AND 
        t.rating IS NOT NULL
    GROUP BY 
        t.rating, TRIM(value)
),
RankedGenres AS (
    SELECT 
        rating,
        listed_in,
        Genre_Count,
        RANK() OVER (PARTITION BY rating ORDER BY Genre_Count DESC) AS Genre_Rank
    FROM 
        GenreCount
)
SELECT 
    rating,
    listed_in,
    Genre_Count,
    Genre_Rank
FROM 
    RankedGenres
WHERE 
    Genre_Rank = 1;

