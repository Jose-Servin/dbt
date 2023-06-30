SELECT
    *
FROM
    {{ ref('dim_listings_clean') }}
WHERE minimum_nights < 1
LIMIT 10
