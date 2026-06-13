import pandas as pd
import os

from dagster import (
    asset,
    AssetExecutionContext,
    MetadataValue,
    RetryPolicy,
)

from dagster_snowflake import SnowflakeResource
from dagster_dbt import dbt_assets,DbtCliResource

from supabase import create_client, ClientOptions

from .resources import dbt_resource, snowflake_resource, dbt_manifest_path


# -----------------------------
# RAW INGESTION ASSET
# -----------------------------
@asset(
    group_name="ingestion",
    description="Extract supply chain data from Supabase and load into Snowflake RAW schema",
    retry_policy=RetryPolicy(max_retries=3, delay=30),
    metadata={
        "source": "supabase",
        "destination": "snowflake.raw.raw_supply_chain",
    },
)
def raw_supply_chain(
    context: AssetExecutionContext,
    snowflake: SnowflakeResource,
) -> None:

    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")

    sb = create_client(
        supabase_url,
        supabase_key,
        options=ClientOptions(schema="public"),
    )

    # note: Full extraction is used here due to small dataset size (~100 rows)
    # and because the Supabase source is a view without an updated_at column.
    # At production scale, this would be replaced with incremental extraction
    # using a watermark column on the underlying table.

    response = sb.table("fact_supply_chain").select("*").execute()
    df = pd.DataFrame(response.data)

    context.log.info(f"Extracted {len(df)} rows from Supabase")

    if df.empty:
        context.log.warning("No data extracted — skipping load")
        return

    with snowflake.get_connection() as conn:
        cursor = conn.cursor()

        cursor.execute("TRUNCATE TABLE IF EXISTS RAW.RAW_SUPPLY_CHAIN")

        cols = df.columns.tolist()
        placeholders = ", ".join(["%s"] * len(cols))
        col_names = ", ".join(cols)

        insert_sql = f"""
            INSERT INTO RAW.RAW_SUPPLY_CHAIN ({col_names})
            VALUES ({placeholders})
        """

        rows = [tuple(row) for row in df.values]

        batch_size = 500
        for i in range(0, len(rows), batch_size):
            batch = rows[i:i + batch_size]
            cursor.executemany(insert_sql, batch)
            context.log.info(
                f"Inserted batch {i // batch_size + 1}: {len(batch)} rows"
            )

    context.add_output_metadata({
        "row_count": MetadataValue.int(len(df)),
        "columns": MetadataValue.text(str(cols)),
    })


# -----------------------------
# DBT ASSETS
# -----------------------------
from dagster_dbt import DagsterDbtTranslator, DagsterDbtTranslatorSettings

dagster_dbt_translator = DagsterDbtTranslator(
    settings=DagsterDbtTranslatorSettings(enable_asset_checks=True)
)


@dbt_assets(
    manifest=dbt_manifest_path,
    exclude="resource_type:seed",
    dagster_dbt_translator=dagster_dbt_translator,
)
def dbt_supply_chain(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build", "--exclude", "resource_type:seed"], context=context).stream()