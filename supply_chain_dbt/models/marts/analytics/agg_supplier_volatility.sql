with s as (
    select * from {{ ref('int_supplier_aggregates') }}
),

b as (
    select * from {{ ref('int_global_baselines') }} limit 1
),

scored as (
    select
        s.supplier_name,
        s.sku_count,
        round(avg_revenue, 2) as avg_revenue,
        round(avg_defect_rate, 3) as avg_defect_rate,
        round(avg_lead_time, 2) as avg_lead_time,

        round(
            {{ weighted_composite(
                z_score('s.revenue_volatility','b.global_rev_vol','b.sd_rev_vol'),
                z_score('s.defect_volatility','b.global_def_vol','b.sd_def_vol'),
                z_score('s.lead_time_volatility','b.global_lead_vol','b.sd_lead_vol'),
                z_score('s.velocity_volatility','b.global_vel_vol','b.sd_vel_vol')
            ) }}
        , 3) as volatility_risk_score

    from s
    cross join b
)

select *,
    rank() over (order by volatility_risk_score desc) as volatility_rank,
    {{ risk_category('volatility_risk_score') }} as risk_category
from scored