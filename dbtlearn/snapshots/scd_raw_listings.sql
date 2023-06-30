{% snapshot scd_raw_listings %}


{# 
    invalidate_hard_deletes=True means our snapshots will reflect any deletes from our raw source tables. 
 #}
{{
   config(
       target_schema='dev',
       unique_key='id',
       strategy='timestamp',
       updated_at='updated_at',
       invalidate_hard_deletes=True
   )
}}

select * FROM {{ source('airbnb', 'listings') }}

{% endsnapshot %}