# DB_Assignment_04
## 1. Top 20 games by number of reviews

```This query shows the most popular games, sorting them by total number of user reviews. A large number of reviews show the high activity of the community, most often due to the success of the game.
SELECT
    g.name,
    s.total_reviews,
    s.review_score_desc
FROM fact_games g
JOIN dim_reviews_stat s ON g.steam_appid = s.appid
ORDER BY s.total_reviews DESC
LIMIT 20;
```
## 2. Support for operating systems (Windows/Mac/Linux)
The analysis showed that there are almost no cross-platform games on Steam, demonstrating the total dominance of Windows as the main platform.
```
SELECT
    COUNT(*) as total_games,
    SUM(CASE WHEN windows THEN 1 ELSE 0 END) as windows_support,
    SUM(CASE WHEN mac THEN 1 ELSE 0 END) as mac_support,
    SUM(CASE WHEN linux THEN 1 ELSE 0 END) as linux_support
FROM fact_games;
```

## 3. Top 10 most popular categories
This insight reveals the most common categories of games, where the "Single-player" category traditionally ranks first.
```
SELECT
    category_name,
    COUNT(*) AS usage_count
FROM dim_categories
GROUP BY category_name
ORDER BY usage_count DESC
    LIMIT 10;
```


## 4. Price dependence on player evaluation (Price vs Sentiment)
The query shows a correlation that mixed-review games often have a higher median price, which may indicate optimization problems or inflated expectations for expensive projects. Instead, the "Overwhelmingly Positive" category is often represented by cheaper games that offer players good value for money.

```
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
```



## 5. The influence of the number of languages on the evaluation of critics (Localization vs Quality)

This insight supports the hypothesis that games with wide localization have a significantly higher average score on Metacritic. 
```
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
```
