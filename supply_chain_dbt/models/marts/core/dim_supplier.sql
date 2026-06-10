SELECT DISTINCT
    supplier_name
FROM {{ ref('stg_supply_chain') }}

--test