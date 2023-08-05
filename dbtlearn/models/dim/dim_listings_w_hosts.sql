{# 

    THIS TABLE SHOULD BE CALLED LISTINGS_AND_HOSTS;
    ALL LISTINGS COME WITH A HOST BY DEFAULT SO LISTINGS_W_HOSTS IS AN INCORRECT WAY TO DESCRIBE THIS DIMENSION TABLE. 
 #}

 {{
  config(
    materialized = 'table'
    )
}}

WITH
l AS (
    SELECT
        *
    FROM
        {{ ref('dim_listings_clean') }}
),
h AS (
    SELECT * 
    FROM {{ ref('dim_hosts_clean') }}
)

SELECT 
    l.listing_id,
    l.listing_name,
    l.room_type,
    l.minimum_nights,
    l.price,
    l.host_id,
    h.host_name,
    h.is_superhost as host_is_superhost,
    l.created_at,
    {# Because both l and h have an updated column and we want whichever is the most recently updated one. #}
    GREATEST(l.updated_at, h.updated_at) as updated_at
FROM l
LEFT JOIN h ON (h.host_id = l.host_id)