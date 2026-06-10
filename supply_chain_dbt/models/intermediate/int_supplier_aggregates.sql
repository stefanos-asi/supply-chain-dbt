with base as (
    SELECT * FROM {{ ref('int_base_metrics') }}
)

select
    supplier_name,
    count(*)                      as sku_count,
    avg(revenue)                  as avg_revenue,
    stddev(revenue)               as revenue_volatility,
    avg(defect_rate)              as avg_defect_rate,
    stddev(defect_rate)           as defect_volatility,
    avg(lead_time_days)           as avg_lead_time,
    stddev(lead_time_days)        as lead_time_volatility,
    avg(revenue_velocity)         as avg_velocity,
    stddev(revenue_velocity)      as velocity_volatility
from base
group by supplier_name