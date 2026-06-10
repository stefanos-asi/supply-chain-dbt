SELECT DISTINCT
    supplier_name,location
FROM {{ ref('stg_supply_chain') }}