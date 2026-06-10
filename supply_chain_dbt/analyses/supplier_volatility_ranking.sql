-- All analyses read from the fct_supply_chain model to ensure consistent metrics and incremental processing

with base_metrics as (
    select
        supplier_name,
        sku,
        revenue,
        defect_rate,
        lead_time_days,
        revenue / nullif(lead_time_days, 0) as revenue_velocity
    from {{ ref('fct_supply_chain') }}
),

supplier_aggregates as (
    select
        supplier_name,
        count(*)                     as sku_count,
        avg(revenue)                 as avg_revenue,
        stddev(revenue)              as revenue_volatility,
        avg(defect_rate)             as avg_defect_rate,
        stddev(defect_rate)          as defect_volatility,
        avg(lead_time_days)          as avg_lead_time,
        stddev(lead_time_days)       as lead_time_volatility,
        avg(revenue_velocity)        as avg_velocity,
        stddev(revenue_velocity)     as velocity_volatility
    from base_metrics
    group by supplier_name
),

global_baselines as (
    select
        avg(revenue_volatility)      as global_rev_vol,
        avg(defect_volatility)       as global_def_vol,
        avg(lead_time_volatility)    as global_lead_vol,
        avg(velocity_volatility)     as global_vel_vol,
        stddev(revenue_volatility)   as sd_rev_vol,
        stddev(defect_volatility)    as sd_def_vol,
        stddev(lead_time_volatility) as sd_lead_vol,
        stddev(velocity_volatility)  as sd_vel_vol
    from supplier_aggregates
),

normalized_scores as (
    select
        s.*,
        {{ z_score('s.revenue_volatility',   'g.global_rev_vol',  'g.sd_rev_vol') }}  as z_rev_vol,
        {{ z_score('s.defect_volatility',    'g.global_def_vol',  'g.sd_def_vol') }}  as z_def_vol,
        {{ z_score('s.lead_time_volatility', 'g.global_lead_vol', 'g.sd_lead_vol') }} as z_lead_vol,
        {{ z_score('s.velocity_volatility',  'g.global_vel_vol',  'g.sd_vel_vol') }}  as z_vel_vol
    from supplier_aggregates s
    cross join global_baselines g
),

risk_scoring as (
    select
        supplier_name,
        sku_count,
        round(avg_revenue, 2)      as avg_revenue,
        round(avg_defect_rate, 3)  as avg_defect_rate,
        round(avg_lead_time, 2)    as avg_lead_time,
        round({{ weighted_composite('z_rev_vol', 'z_def_vol', 'z_lead_vol', 'z_vel_vol') }}, 3) as volatility_risk_score
    from normalized_scores
)

select
    supplier_name,
    sku_count,
    avg_revenue,
    avg_defect_rate,
    avg_lead_time,
    volatility_risk_score,
    rank() over (order by volatility_risk_score desc) as volatility_rank,
    {{ risk_category('volatility_risk_score') }}      as risk_category
from risk_scoring
order by volatility_rank