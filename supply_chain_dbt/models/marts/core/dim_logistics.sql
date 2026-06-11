select distinct
    shipping_carriers,
    transportation_modes,
    routes
from {{ ref('stg_supply_chain') }}

--test