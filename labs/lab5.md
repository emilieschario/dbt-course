## Lab 5: Window Functions, Calendar Spines, and Semi-Structured Data

### 1. Add a `days_since_last_order` column to the `orders` model.

It's useful for analysis to know how many days had passed between an order and the prior order (for a given customer).

Using a window function, add a column `days_since_last_order` to the `orders` model.

<details>
  <summary>👉 Section 1</summary>

  (1) To calculate `days_since_last_order` we need to add the following SQL (or similar depending on what you've named columns) to our `orders` model. It finds the prior order for a customer and calculates the difference in days between the two `ordered_at` values:
  ```sql
    datediff('day', lag(ordered_at) over (partition by customer_id order by ordered_at), ordered_at)
  ```
  (2) Execute `dbt run -m order` to make sure your model runs successfully.
</details>

### 2. Filter out employees from the orders and customers models

Employees get a discount from our ecommerce shop. While we're very happy for them to have that discount, we want to filter out all of their records from the warehouse.

If you haven't already, create a staging model for the customers data. In the staging model, filter out all emails for the domains `ecommerce.com`, `ecommerce.co.uk`, `ecommerce.ca`.

That filter should fix the customers data, but we still need to add a filter to the `orders` model. Filter out any employee orders.

<details>
  <summary>👉 Section 2</summary>

  (1) As discussed in the session, there are a number of different ways we could do this filter. In this instance we'll use an `ilike`. Add the following filter to your customers model:
  ```sql
    where email not ilike '%ecommerce.com'
      and email not ilike '%ecommerce.ca'
      and email not ilike '%ecommerce.co.uk'
  ```
  (2) Add the same filter to your `orders` model. Note that the `email` column isn't likely to already be there so you might need to join it in.
  (3) Execute `dbt run` to make sure your filters work.
</details>

### 3. Create a staging model for the payments data

We've recently integrated our payments data into Snowflake. The data comes as a JSON API response from the source system and we decided it would be easier to just put it in Snowflake in the same format.

The table can be found at `raw.stripe.payments`.

Create a staging model for the new payments data that includes the following fields:
* order_id
* payment_id
* payment_type
* payment_amount
* created_at

Things to think about:
* Does our new model need tests?
* Does every column have the correct datatype?

<details>
  <summary>👉 Section 3</summary>

  (1) Add a new source for the Stripe data.

  (2) Create a new file `stg_stripe__payments.sql` in our `models/` directory.

  (3) Pull out the necessary columns from the JSON. Write a query around the following column definitions:
  ```sql
    json_data:order_id as order_id,
    json_data:id as payment_id,
    json_data:method as payment_type,
    json_data:amount::int / 100.0 as payment_amount,
    json_data:created_at::timestamp as created_at
  ```

  (4) Execute `dbt run -m stg_stripe__payments` to make sure everything is working correctly.

</details>

### 4. Write a query that provides a record for each zipcode

As part of the payments data work, we also received a dataset with information about US zipcodes. Again, this data has been provided to us as a single JSON object and we want to unnest it so that each record contains a zipcode and relevant information about that zipcode.

Write a query, using a `lateral flatten`, that contains a record for each zipcode in our new dataset.

The data for this exercise can be found at `raw.geo.countries`.

<details>
  <summary>👉 Section 4</summary>

  (1) In a new SQL query, inspect the format of the table by running `select * from raw.geo.countries`.

  (2) Let's 'unnest' the `states` array by adding a `lateral flatten` to the query:
  ```sql
    select
        country,
        s.value:state as state,
        s.value:zipcodes as zipcodes
    from raw.geo.countries
    left join lateral flatten (input => states) as s
  ```
  We now have a record for each state, which we can see has another array in it called `zipcodes`.

  (3) Let's 'unnest' the `zipcodes` array by adding another `lateral flatten`:
  ```sql
    select
        country,
        s.value:state as state,
        c.value:zipcode as zipcode,
        c.value:city as city
    from raw.geo.countries
    left join lateral flatten (input => states) as s
    left join lateral flatten (input => s.value:zipcodes) as c
  ```

  (4) It looks like some of our columns aren't coming through as the correct data type. Let's cast them to strings:
  ```sql
    select
        country,
        s.value:state::varchar as state,
        c.value:zipcode::varchar as zipcode,
        c.value:city::varchar as city
    from raw.geo.countries
    left join lateral flatten (input => states) as s
    left join lateral flatten (input => s.value:zipcodes) as c
  ```
  We should now have a complete query.

</details>

### 5. Create a `customer__daily` model

Because customers regularly change their addresses, our support team want to know what address a customer had in a system on a given day.

First, create a calendar spine using the dbt-utils package.

Then, create a model called `customer__daily` that uses our snapshot data and the calendar spine to have a record of what a customer looked like on each day since they were created.

**N.B.**: For the purposes of this exercise, given we don't have our own snapshot data, please use the following table for the snapshot data: `analytics.snapshots_prod.customers_snapshot`.

<details>
  <summary>👉 Section 5</summary>

  (1) Create a `packages.yml` file in the root directory of your project. Add the following code to it to add the `dbt_utils` package:
  ```yaml
  packages:
    - package: fishtown-analytics/dbt_utils
      version: 0.6.4
  ```
  Make sure you run `dbt deps` so that this package is imported into your project.

  (2) Create a new model called `calendar.sql`. Add the following code to it to generate a calendar spine:
  ```sql
  {{ dbt_utils.date_spine(
      datepart="day",
      start_date="to_date('01/01/2020', 'mm/dd/yyyy')",
      end_date="current_date"
    )
  }}
  ```
  (3) Create a new model called `customer__daily.sql`. Add the following SQL:
  ```sql
  with calendar as (

      select *
      from {{ ref('calendar') }}

  ), customers as (

      select *
      from analytics.snapshots_prod.customers_snapshot

  ), joined as (

      select
          calendar.date_day,
          customers.*
      from calendar
      inner join customers
          on calendar.date_day < coalesce(customers._dbt_valid_to, '2099-01-01')
          and calendar.date_day >= customers._dbt_valid_from

  )

  select *
  from joined
  ```
  (4) Execute `dbt run -m +customer__daily` to make sure your models run successfully.
</details>

### 6. Write a query that shows rolling 7-day order volumes

You've had a request from the CEO to create a dashboard with the rolling 7-day order amounts. Because some days don't have orders, you think you'll need to use a calendar spine to create it.

Write a query that shows the number of orders on a rolling 7-day basis.

<details>
  <summary>👉 Section 6</summary>

  (1) Write a SQL query that joins our `orders` and `calendar` models. The join should work in a such a way that the prior 7 days of orders get joined to a given `date_day` in the `calendar` model. That way, you can then aggregate this joined query, grouping by the `date_day` column, in order to count how many orders there were on a rolling 7 day basis.
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [Snowflake Docs: Functions](https://docs.snowflake.com/en/sql-reference/functions-all.html)
* [Snowflake Docs: Window Functions](https://docs.snowflake.com/en/sql-reference/functions-analytic.html)
* [Snowflake Docs: Querying Semi-Structured Data](https://docs.snowflake.com/en/user-guide/querying-semistructured.html)
* [dbt Docs: Packages](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/)
* [Slides from presentation](https://docs.google.com/presentation/d/1CJCWaFTe0PHJ2K9ltryJdTmZB7k07cYTi4TJisu9LHw/edit?usp=sharing)
