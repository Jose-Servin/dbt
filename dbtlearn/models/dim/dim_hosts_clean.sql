{# 
    BY DEFAULT, dim IS BEING MATERIALIZED AS A TABLE
    SO HERE WE ARE OVERRIDING THE DEFINED PARENT DIRECTORY BEHAVIOR.
 #}

{{
  config(
    materialized = 'view'
    )
}}

WITH src_hosts AS (
    select * from {{ ref('src_hosts') }}
)
SELECT
    host_id,
    NVL(host_name, 'Anonymous') as host_name,
    is_superhost,
    created_at,
    updated_at
FROM 
    src_hosts  

