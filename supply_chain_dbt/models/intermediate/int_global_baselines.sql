with supplier_agg as (
    select * from {{ ref('int_supplier_aggregates') }}
)

select
    avg(revenue_volatility)      as global_rev_vol,
    avg(defect_volatility)       as global_def_vol,
    avg(lead_time_volatility)    as global_lead_vol,
    avg(velocity_volatility)     as global_vel_vol,
    stddev(revenue_volatility)   as sd_rev_vol,
    stddev(defect_volatility)    as sd_def_vol,
    stddev(lead_time_volatility) as sd_lead_vol,
    stddev(velocity_volatility)  as sd_vel_vol
from supplier_agg
