from dagster import EnvVar
from dagster_snowflake import SnowflakeResource
from dagster_dbt import DbtCliResource
import os

PROJECT_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../supply_chain_dbt")
)

snowflake_resource = SnowflakeResource(
    account=EnvVar("SNOWFLAKE_ACCOUNT"),
    user=EnvVar("DBT_USER"),
    private_key_path=EnvVar("PRIVATE_KEY_PATH"),
    private_key_password=EnvVar("PRIVATE_KEY_PASSPHRASE"),
    warehouse="DEV_WH",
    database="SUPPLY_CHAIN",
    schema="RAW",
    role="DBT_ROLE",
)

dbt_resource = DbtCliResource(
    project_dir=PROJECT_DIR,
    profiles_dir=r"C:/Users/User/.dbt",
)

dbt_manifest_path = os.path.join(
    PROJECT_DIR,
    "target",
    "manifest.json"
)