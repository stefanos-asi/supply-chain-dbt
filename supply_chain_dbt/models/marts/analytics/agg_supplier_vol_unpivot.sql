{{
    config(
        materialized='table',
        schema='ANALYTICS'
    )
}}

with supplier_agg as (
    select * from {{ ref('int_supplier_aggregates') }}
)

select
    supplier_name,
    case volatility_type
        when 'REVENUE_VOLATILITY' then 'Revenue Volatility'
        when 'DEFECT_VOLATILITY' then 'Defect Rate Volatility'
        when 'LEAD_TIME_VOLATILITY' then 'Lead Time Volatility'
        when 'VELOCITY_VOLATILITY' then 'Velocity Volatility'
    end as volatility_type,
    volatility_value,
    ntile(4) over (
        partition by volatility_type
        order by volatility_value
    ) as quartile
from supplier_agg
unpivot (
    volatility_value for volatility_type in (
        revenue_volatility,
        defect_volatility,
        lead_time_volatility,
        velocity_volatility
    )
)