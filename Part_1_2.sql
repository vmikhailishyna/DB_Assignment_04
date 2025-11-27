drop table if exists raw_data_reviews;
create table raw_data_games as
SELECT *
FROM read_json_auto('Databases\Assignment_04\steam_2025_5k-dataset-games_20250831.json.gz',
                    maximum_object_size = 1004857600);


create or replace table raw_games as
       select unnest(games) as game_data
       from raw_data_games;

select *
from raw_games
limit 10;

create or replace table stage_games as
select
    UNNEST(game_data.app_details.data)
from raw_games;

select *
from stage_games
         limit 10;

DESCRIBE stage_games;

create or replace table fact_games as
select
    steam_appid,
    name,
    required_age,
    is_free,
    controller_support,
    type,
    COALESCE(price_overview.final / 100.0, 0) AS price_usd,
    price_overview.currency,
    price_overview.discount_percent,
    metacritic.score AS metacritic_score,
    recommendations.total AS recommendations_count,
    regexp_replace(supported_languages, '<[^>]+>', '', 'g') AS supported_languages,
    UNNEST(platforms),
    UNNEST(release_date)
from stage_games;

select *
from fact_games
         limit 1000;

CREATE OR REPLACE TABLE dim_categories AS
SELECT DISTINCT
    steam_appid,
    UNNEST(categories).description AS category_name,
    UNNEST(categories).id AS category_id
FROM stage_games
WHERE categories IS NOT NULL;

select *
from dim_categories
         limit 10;

create table raw_data_reviews as
SELECT *
FROM read_json_auto('Databases\Assignment_04\steam_2025_5k-dataset-reviews_20250901.json.gz',
                    maximum_object_size = 1004857600);


create or replace table raw_reviews as
select unnest(reviews) as reviews_data
from raw_data_reviews;

select *
from raw_reviews
         limit 10;

CREATE OR REPLACE TABLE stage_reviews as
select
    reviews_data.appid,
    UNNEST(reviews_data.review_data.reviews) AS r_data
FROM raw_reviews;

CREATE OR REPLACE TABLE dim_reviews AS
SELECT
    appid,
    r_data.recommendationid AS review_id,
    r_data.review AS review_text,
    CAST(r_data.voted_up AS BOOLEAN) AS is_positive,
    r_data.author.steamid AS author_id,
    to_timestamp(r_data.timestamp_created) AS created_at
FROM stage_reviews;


select *
from dim_reviews
         limit 10;

CREATE OR REPLACE TABLE dim_reviews_stat AS
SELECT
    reviews_data.appid,
    UNNEST(reviews_data.review_data.query_summary)
FROM raw_reviews;

select *
from dim_reviews_stat
         limit 10;







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
