# AllThingsdbt

## VSCode Extensions

1. dbt Power User

    Activated by editing settings.json with file association definition.

    ```JSON
    "files.associations": {
        "*.sql" : "jinja-sql"
    },
    ```

## Project Intro

Manage a simple dbt project using Airbnb data + dbt + Snowflake. Create a standard/enterprise data flow and leverage dbt plus extensions to deliver a well documented dbt project.

* 3 sources come directly from AirBnb

1. `RAW_HOSTS`
2. `RAW_LISTINGS`
3. `RAW_REVIEWS`

* 1 source comes from "external" side - full moons data as csv.

1. `seed_full_moon_dates.csv`

### Data Flow

RAW --> SRC(SOURCE) --> DIM/FACT --> MART -->  DASHBOARD/BI TOOL

#### Raw Layer

* Represents the raw data from AirBnB that was brought into Snowflake from an S3 Bucket - `AIRBNB.RAW`

#### Staging Layer

* Represented by SRC(SOURCE) models. The purpose of this layer is to take RAW sources and apply column or data type formatting to create
a `SRC_` model for DIM and MART models.

* Ambiguous column names like "name" and "id" are changed to reference their source "listing_name", "listing_id".
* Materialized as `view` since our sources won't be accessed that frequent.

#### Core Layer

* Represented by DIM/FCT tables.
* `dim_listings_cleansed.sql` + `dim_hosts_cleansed.sql` = `dim_listings_with_hosts.sql`
* `fct_reviews.sql`
* Model dependency plays a big role in Core Layer when executing `dbt build` (compilation) and `dbt run` (execution).
* Usage of `{{ ref('src_listings') }}` defines the Parent/Child relationship for dbt docs and dbt Power User.
* Materialized as `table` since Core Layer models will be accessed quite often.

#### More about [ref Jinja function](https://docs.getdbt.com/reference/dbt-jinja-functions/ref)

```text
First, it is interpolating the schema into your model file to allow you to change your deployment schema via configuration. Second, it is using these references between models to automatically build the dependency graph. 
```

#### More about `fct_reviews` model

This model will update only when new reviews are added to our source - this prevents this fact table from rebuilding every time `dbt run` runs. [More info here](https://docs.getdbt.com/docs/build/incremental-models)

So, to add the sql logic that states "only add new or updated records that have been created since last dbt run" we use:

```sql
{% if is_incremental() %}
  AND review_date > (select max(review_date) from {{ this }})
{% endif %}
```

plus a hashed surrogate key in our model:

```sql
{{ dbt_utils.generate_surrogate_key(['listing_id', 'review_date', 'reviewer_name', 'review_text']) }}
    AS review_id,
```

#### More about ephemeral models

We've converted our `src_` models to be materialized as ephemeral models which basically does NOT bring them into the database and keeps the sql as a CTE.

```yml
src:
      # ephemeral models are not directly built into the database.
      # Instead, dbt will interpolate the code from this model into dependent models as a CTE.
      # see target/ directory for compiled sql
      +materialized: ephemeral
```

Note: model might need to be dropped explicitly from DB if they were already materialized.

We can view the compiled sql for any model in our `target/` directory.

### Target Directory

* Path `dbtlearn/target/run/dbtlearn/models/dim/dim_listings_clean.sql`

Here you can find the final compiled sql which can help debug as well as the CTE for our ephemeral materialized models:

```sql
WITH  __dbt__cte__src_listings as (
WITH raw_listings AS (
    SELECT
        *
    FROM
        AIRBNB.raw.raw_listings
)
```

## Seeds and Sources

Our `source.yml` file serves as an abstraction layer on-top of our input data for dbt.

We can check various conditions about the data such as freshness and define references.

To implement:

1. add a `source.yml` file which maps to actual models in our DB.

2. reference these models using `{{ source('airbnb', 'reviews') }}`.

3. run `dbt compile` to make sure there are no source ref errors.

### Source Freshness

Source freshness is checked using a build in dbt function and run command.

1. Define what column in what table to look for "freshness".

In the raw reviews table look at the `date` column and see if any values break the freshness rules defined.

```yml

- name: reviews
        identifier: raw_reviews
        loaded_at_field: date
        freshness:
          warn_after: { count: 1, period: hour }
          error_after: { count: 24, period: hour }

```

2. run `dbt source freshness`

![Error message for stale data using dbt source freshness command.](./Notes-SC/source-freshness-error.png)