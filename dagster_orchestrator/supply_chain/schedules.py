from dagster import ScheduleDefinition, DefaultScheduleStatus
from supply_chain.assets import dbt_supply_chain, raw_supply_chain

# run the full pipeline daily at 6am UTC
daily_refresh = ScheduleDefinition(
    name="daily_supply_chain_refresh",
    target=[raw_supply_chain, dbt_supply_chain],
    cron_schedule="0 6 * * *",
    default_status=DefaultScheduleStatus.RUNNING,
    description="Daily ingestion from Supabase + dbt build",
)