-- All analyses read from the fct_supply_chain model to ensure consistent metrics and incremental processing

with sku_metrics as (
    select
        sku, product_type, revenue, defect_rate, lead_time_days,
        stock_levels, units_sold,
        stock_levels::numeric / nullif(units_sold, 0) as stock_sales_ratio
    from {{ ref('fct_supply_chain') }}
),

risk_scoring as (
    select
        sku, product_type, revenue,
        percent_rank() over (order by revenue desc)          as revenue_percentile,
        percent_rank() over (order by defect_rate desc)      as defect_percentile,
        percent_rank() over (order by lead_time_days desc)   as lead_time_percentile,
        percent_rank() over (order by stock_sales_ratio desc) as stock_risk_percentile
    from sku_metrics
)

select
    sku,
    product_type,
    round(revenue_percentile, 2)                                             as revenue_pct,
    round(defect_percentile * 0.4 + lead_time_percentile * 0.3 + stock_risk_percentile * 0.3, 3) as operational_risk_score,
    case
        when revenue_percentile > 0.75
         and (defect_percentile * 0.4 + lead_time_percentile * 0.3 + stock_risk_percentile * 0.3) > 0.6
        then 'HIGH REVENUE - HIGH RISK'
        else 'STABLE'
    end as risk_flag
from risk_scoring
order by operational_risk_score desc