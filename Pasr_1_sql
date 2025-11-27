drop table if exists raw_data_reviews;
create table raw_data_games as
SELECT *
FROM read_json_auto('Assignment_04\steam_2025_5k-dataset-games_20250831.json.gz',
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
         limit 10;

create table raw_data_reviews as
SELECT *
FROM read_json_auto('Assignment_04\steam_2025_5k-dataset-reviews_20250901.json.gz',
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
from dim_reviews
         limit 10;
