SELECT
    g.name,
    s.total_reviews,
    s.review_score_desc
FROM fact_games g
JOIN dim_reviews_stat s ON g.steam_appid = s.appid
ORDER BY s.total_reviews DESC
LIMIT 20;


SELECT
    COUNT(*) as total_games,
    SUM(CASE WHEN windows THEN 1 ELSE 0 END) as windows_support,
    SUM(CASE WHEN mac THEN 1 ELSE 0 END) as mac_support,
    SUM(CASE WHEN linux THEN 1 ELSE 0 END) as linux_support
FROM fact_games;

SELECT
    category_name,
    COUNT(*) AS usage_count
FROM dim_categories
GROUP BY category_name
ORDER BY usage_count DESC
    LIMIT 10;


SELECT
    s.review_score_desc as review_score,
    COUNT(*) as game_count,
    ROUND(MEDIAN(g.price_usd), 2) as median_price
from fact_games g
Join dim_reviews_stat s ON g.steam_appid=s.appid
WHERE g.price_usd > 0
  AND s.review_score_desc NOT LIKE '%user reviews%'
GROUP BY s.review_score_desc
HAVING game_count > 10
order by median_price DESC;

SELECT
    EXTRACT(YEAR FROM try_cast(date AS DATE)) AS release_year,
    COUNT(*) AS games_count
FROM fact_games
WHERE date IS NOT NULL
GROUP BY release_year
ORDER BY release_year DESC;


with game_language_count as(
    SELECT steam_appid,
           metacritic_score,
           len(string_split(supported_languages, ',')) as language_count
    from fact_games
)
SELECT
    language_count,
    COUNT(*) as total_games,
    ROUND(AVG(metacritic_score), 1) as avg_score
FROM game_language_count
WHERE metacritic_score > 0
AND language_count is not NULL
GROUP BY language_count
ORDER BY language_count DESC;
