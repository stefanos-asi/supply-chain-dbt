SELECT DISTINCT
    sku,
    product_type,
    price
FROM {{ ref('stg_supply_chain') }}