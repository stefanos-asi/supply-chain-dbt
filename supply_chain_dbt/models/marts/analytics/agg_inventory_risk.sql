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
    sku,
    product_type,
    stock_levels,
    units_sold,
    lead_time_days,
    avg(stock_levels) over (partition by product_type)                         as avg_stock_category,
    avg(units_sold) over (partition by product_type)                           as avg_sales_category,
    round(stock_levels::numeric / nullif(units_sold, 0), 2)                   as stock_to_sales_ratio,
    case
        when stock_levels < avg(stock_levels) over (partition by product_type)
         and lead_time_days > 20 then 'High Risk'
        when stock_levels < avg(stock_levels) over (partition by product_type)
        then 'Medium Risk'
        else 'Low Risk'
    end                                                                        as inventory_risk_level
from fct