{{
    config(
        materialized='incremental',
        unique_key='sku',
        schema='ANALYTICS',
        on_schema_change='sync_all_columns'
    )


}}


select
    sku,
    product_type,
    supplier_name,
    location,
    units_sold,
    revenue,
    total_costs,
    shipping_costs,
    manufacturing_costs,
    stock_levels,
    lead_time_days,
    mfg_lead_time_days,
    shipping_time_days,
    defect_rate
from {{ ref('stg_supply_chain') }}

{% if is_incremental() %}
    where sku not in (select sku from {{ this }})
{% endif %}