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
    supplier_name,
    revenue,
    (revenue - total_costs)                                                    as profit,
    round((revenue - total_costs) / nullif(revenue, 0) * 100, 2)              as margin_pct,
    rank() over (partition by product_type order by revenue)                   as revenue_rank_category,
    sum(revenue) over (
        partition by product_type
        order by revenue desc
        rows between unbounded preceding and current row
    )                                                                          as cumulative_revenue
from fct