from dagster import Definitions
from supply_chain.assets import raw_supply_chain, dbt_supply_chain
from supply_chain.resources import snowflake_resource, dbt_resource
from supply_chain.schedules import daily_refresh

defs = Definitions(
    assets=[raw_supply_chain, dbt_supply_chain],
    schedules=[daily_refresh],
    resources={
        "snowflake": snowflake_resource,
        "dbt": dbt_resource,
    },
)