with calendar as (

    select *
    from {{ ref('calendar') }}

), customers as (

    select *
    from {{ ref('stg_snapshot__customers') }}

), joined as (

    select 
        calendar.date_day,
        customers.*
    from calendar
    inner join customers
        on calendar.date_day < coalesce(customers.dbt_valid_to, '2099-01-01')
        and calendar.date_day >= customers.dbt_valid_from

)

select *
from joined