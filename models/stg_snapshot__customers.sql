with base as (

    select *
    from {{ ref('customers_snapshot') }}

), fields as (

    select 
        id as customer_id,
        first_name,
        last_name,
        email,
        address,
        phone_number,
        created_at,
        dbt_valid_from,
        dbt_valid_to
    from base

)

select *
from fields