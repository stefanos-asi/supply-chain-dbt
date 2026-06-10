with source as (
    SELECT *
    FROM {{ source('raw', 'raw_supply_chain') }}
)

select
    sku,
    product_type,
    supplier_name,
    location,
    cast(price as numeric(12,2))                   as price,
    cast(number_of_products_sold as integer)        as units_sold,
    cast(revenue_generated as numeric(12,2))        as revenue,
    cast(costs as numeric(12,2))                    as total_costs,
    cast(shipping_costs as numeric(12,2))           as shipping_costs,
    cast(manufacturing_costs as numeric(12,2))      as manufacturing_costs,
    cast(stock_levels as integer)                   as stock_levels,
    cast(supplier_lead_time as integer)             as lead_time_days,
    cast(manufacturing_lead_time as integer)        as mfg_lead_time_days,
    cast(shipping_times as integer)                 as shipping_time_days,
    cast(defect_rates as numeric(8,4))              as defect_rate,
    shipping_carriers,
    transportation_modes,
    routes,
    inspection_results,
    customer_demographics
from source
where sku is not null