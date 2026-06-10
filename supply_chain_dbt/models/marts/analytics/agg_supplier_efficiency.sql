{{
    config(
        materialized='table',
        schema='ANALYTICS'
    )
}}

with fct as (
    select * from {{ ref('fct_supply_chain') }}
)

select
    supplier_name,
    avg(lead_time_days)                                                        as avg_lead_time,
    avg(defect_rate)                                                           as avg_defect_rate,
    avg(shipping_costs)                                                        as avg_shipping_costs,
    sum(revenue)                                                               as total_revenue,
    round(
        sum(revenue) / nullif(avg(defect_rate + 1) * avg(lead_time_days), 0),
        2
    )                                                                          as supplier_efficiency_score
from fct
group by supplier_name
order by supplier_name