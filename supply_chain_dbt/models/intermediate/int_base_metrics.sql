-- mirrors the base_metrics CTE — adds revenue velocity
with stg as (
    select * from {{ ref('stg_supply_chain') }}
)
--Testing for circle ci
select
    supplier_name,
    sku,
    revenue,
    defect_rate,
    lead_time_days,
    revenue / nullif(lead_time_days, 0) as revenue_velocity
from stg