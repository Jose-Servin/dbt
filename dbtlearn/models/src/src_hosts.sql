WITH raw_hosts AS (
SELECT * FROM AIRBNB.RAW.RAW_HOSTS
)
SELECT
ID as host_id,
name as host_name,
is_superhost,
created_at,
updated_at
from raw_hosts