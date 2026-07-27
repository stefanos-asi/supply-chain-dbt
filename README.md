# Supplier Risk Intelligence Platform

> End-to-end data platform built on MDS, Power BI & Streamlit

![dbt](https://img.shields.io/badge/dbt-1.8.4-FF694B?style=flat&logo=dbt&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=flat&logo=snowflake&logoColor=white)
![Dagster](https://img.shields.io/badge/Dagster-6B4FBB?style=flat&logo=dagster&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat&logo=python&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?style=flat&logo=githubactions&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![Streamlit](https://img.shields.io/badge/Streamlit-FF4B4B?style=flat&logo=streamlit&logoColor=white)

---

## What This Project Does

Supply chain risk is hard to quantify because averages hide volatility. A supplier who delivers in 5 days one week and 25 days the next has the same average as a perfectly reliable one — but poses completely different operational risk.

This platform measures **unpredictability directly**. It computes supplier-level volatility metrics (standard deviation across SKUs), normalises them into z-scores, and combines them into a composite risk score. Every supplier gets a score and a category: STABLE, MODERATE, HIGH VOLATILITY, or CRITICAL VOLATILITY.

The result is a production-grade pipeline that runs daily, tests itself, alerts on failure, and serves both a BI dashboard and an ML prediction app.

---

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌──────────────────────────────────────┐
│   Supabase  │────▶│   Dagster   │────▶│              Snowflake               │
│ (PostgreSQL)│     │(Orchestrate)│     │                                      │
│  Source DB  │     │ Daily 6am   │     │  RAW → dbt → PROD_STAGING            │
└─────────────┘     │ Slack alerts│     │             PROD_ANALYTICS           │
                    └─────────────┘     └──────────┬───────────────────────────┘
                                                   │
                          ┌────────────────────────┼──────────────────────┐
                          ▼                        ▼                      ▼
                   ┌─────────────┐        ┌──────────────┐      ┌──────────────┐
                   │  Power BI   │        │  Streamlit   │      │  dbt Docs    │
                   │  Dashboard  │        │   ML App     │      │   Lineage    │
                   └─────────────┘        └──────────────┘      └──────────────┘
```

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Source | Supabase (PostgreSQL) | Operational database — raw supply chain records |
| Ingestion | Dagster | Daily pipeline orchestration, retry logic, Slack alerts |
| Warehouse | Snowflake | Cloud analytical warehouse (Azure West Europe) |
| Transformation | dbt | Staged transformations, tests, macros, CI/CD |
| CI/CD | GitHub Actions | Slim CI on PRs, full prod build on merge |
| BI | Power BI | Executive dashboard (Import mode, Snowflake connection) |
| ML | Python + Streamlit | live risk predictions |

---

## Repository Structure

```
supply-chain-dbt/
├── supply_chain_dbt/               # dbt project
│   ├── models/
│   │   ├── staging/                # stg_supply_chain (view)
│   │   ├── intermediate/           # int_base_metrics, int_supplier_aggregates, int_global_baselines (ephemeral)
│   │   └── marts/
│   │       ├── core/               # fct_supply_chain (incremental), dim_* tables
│   │       └── analytics/          # agg_supplier_volatility, agg_product_performance, etc.
│   ├── macros/                     # z_score(), weighted_composite(), risk_category()
│   ├── tests/                      # assert_risk_score_bounds custom test
│   ├── analyses/                   # hidden_risk_skus.sql, supplier_volatility_ranking.sql
│   ├── seeds/                      # raw_supply_chain.csv (CI test fixture)
│   └── dbt_project.yml
├── dagster_orchestrator/           # Dagster pipeline
│   └── supply_chain/
│       ├── assets.py               # Supabase ingestion + dbt_assets
│       ├── resources.py            # SnowflakeResource, DbtCliResource
│       ├── schedules.py            # Daily 6am UTC schedule
│       ├── notifications.py        # Slack failure sensor
│       └── definitions.py          # Entry point
└── .github/
    └── workflows/
        └── dbt_ci.yml              # CI/CD pipeline
```

---

## dbt Model DAG

```
RAW.raw_supply_chain (source / seed)
  │
  └── stg_supply_chain (view)
        │
        ├── fct_supply_chain (incremental)        ← materialisation boundary
        │     ├── agg_product_performance (table)
        │     ├── agg_supplier_efficiency (table)
        │     └── agg_inventory_risk (table)
        │
        ├── int_base_metrics (ephemeral)
        │     └── int_supplier_aggregates (ephemeral)
        │           └── int_global_baselines (ephemeral)
        │                 ├── agg_supplier_volatility (table)
        │                 └── agg_supplier_vol_unpivot (table)
        │
        ├── dim_product (table)
        ├── dim_supplier (table)
        │     └── dim_supplier_loc (table)
        └── dim_logistics (table)
```

**Exposures (downstream consumers):**
- `power_bi_supply_chain_dashboard` → Power BI
- `streamlit_supplier_risk_prediction` → Streamlit ML app

---

## Risk Scoring Formula

```
score = z(revenue_volatility)    × 0.30
      + z(defect_volatility)     × 0.30
      + z(lead_time_volatility)  × 0.20
      + z(velocity_volatility)   × 0.20
```

| Score | Category |
|---|---|
| > 1.5 | CRITICAL VOLATILITY |
| 0.5 to 1.5 | HIGH VOLATILITY |
| -0.5 to 0.5 | MODERATE |
| < -0.5 | STABLE |

The formula is implemented in three places kept in sync:
1. **dbt** — `agg_supplier_volatility.sql` (source of truth)
2. **Python** — `supply_utils.py compute_supplier_stats()` (mirrors the SQL)
3. **Test** — `test_parity.py` verifies both produce identical results to ±0.01

---

## CI/CD Pipeline

```
PR opened
  ├── dbt seed (test fixture)
  ├── Download prod manifest (slim CI)
  ├── dbt build --select state:modified+ --defer --state prod_manifest/
  ├── All tests must pass
  └── Drop throwaway schemas (PR_<run_id>_STAGING, PR_<run_id>_ANALYTICS)

Merge to main
  ├── dbt build --target prod (full build)
  ├── All tests must pass
  └── Upload manifest.json (enables slim CI on next PR)
```

**Branch protection:** Direct pushes to `main` are blocked. The `dbt_run` status check must pass before merging.

**Slim CI:** After the first successful prod run, subsequent PRs only build changed models and their downstream dependencies using `dbt --select state:modified+ --defer`.

---

## Dagster Pipeline

Daily at 6am UTC:

1. **`raw_supply_chain`** — Extracts from Supabase, loads into `RAW.RAW_SUPPLY_CHAIN` (truncate + reload, batch size 500). Retry: 3× with 30s delay.
2. **`dbt_supply_chain`** — Runs `dbt build` across all models and tests.
3. **Slack sensor** — Posts structured failure alerts to `#data-pipelines`.

```bash
cd dagster_orchestrator
dagster dev
# Open http://localhost:3000
```

---

## Local Setup

### Prerequisites
- Python 3.12+
- Snowflake account ([free trial](https://signup.snowflake.com))
- Supabase project with `fact_supply_chain` table
- RSA key pair for Snowflake authentication

### Steps

```bash
# 1. Clone
git clone https://github.com/stefanos-asi/supply-chain-dbt.git
cd supply-chain-dbt

# 2. Create venv
python -m venv .venv && .venv\Scripts\activate  # Windows

# 3. Install dbt
pip install dbt-snowflake==1.8.4

# 4. Set up .env (see .env.example)
cp .env.example .env
# Fill in your Snowflake account, key path, passphrase, Supabase credentials

# 5. Load env vars (PowerShell)
Get-Content .env | ForEach-Object { if ($_ -match '^(.*?)=(.*)$') { [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2]) } }

# 6. Test connection
cd supply_chain_dbt && dbt debug

# 7. Build
dbt seed && dbt build
```

### Snowflake Setup

## GitHub Secrets

| Secret | Description |
|---|---|
| `SNOWFLAKE_ACCOUNT` | Account identifier |
| `DBT_USER` | dbt service account |
| `DBT_CI_USER` | CI user |
| `DBT_PROD_USER` | Prod user |
| `SNOWFLAKE_PRIVATE_KEY` | Full PEM content including headers |
| `SNOWFLAKE_CI_PRIVATE_KEY` | CI private key |
| `SNOWFLAKE_PROD_PRIVATE_KEY` | Prod private key |
| `PRIVATE_KEY_PASSPHRASE` | RSA key passphrase |

---

## Design Decisions

| Decision | Rationale |
|---|---|
| Incremental `fct_supply_chain` | Mirrors production — only new SKUs added per run |
| Ephemeral intermediates | No physical warehouse objects for building-block CTEs |
| Seed in CI, Dagster in prod | CI needs static test data; Dagster owns live ingestion |
| Import mode in Power BI | Full DAX support, zero Snowflake credits on user interactions |
| Separate CI/prod Snowflake users | Isolated credentials per environment |
| Ridge over XGBoost tiebreak | Linear target → simpler model correct choice |

---

## Related

- [**supplier-risk-app**](https://github.com/stefanos-asi/supplier-risk-app) — Streamlit ML application
- [**Portfolio**](https://stefanos-asi.github.io/portfolio_website/)

---

## ML Model

The [Streamlit app](https://supplier-risk-app-zbkocpafdc2rd8c93zcznq.streamlit.app/) predicts `volatility_risk_score` 
from 11 features (3 SKU-level + 8 supplier-level). The winning model is selected 
automatically on each training run based on hold-out R².

**Model comparison:** Four models are trained and compared on every run:

| Model | Notes |
|---|---|
| Linear Regression | Baseline — no regularisation |
| Ridge Regression | L2 regularisation — preferred on small datasets |
| Random Forest | Checks for non-linear interaction effects |
| XGBoost | Gradient boosted trees — most powerful but hardest to justify on a linear target |

**Selection logic:** The model with the highest hold-out R² on real data wins.

**Key decisions:**
- **Regression not classification** — the risk category is a deterministic bucketing of the continuous score; classifying would just learn threshold rules and lose information
- **Synthetic augmentation** — 800 samples generated with 8% Gaussian noise; target recomputed from noisy features to prevent data leakage
- **Hold-out evaluation on real data only** — model is never evaluated on synthetic samples, giving honest performance estimates

---

## Author

**Stefanos Asiklaris** — Assistant Manager at PwC

[LinkedIn](https://www.linkedin.com/in/stefanos-asiklaris-899952283/) · [Portfolio](https://stefanos-asi.github.io/portfolio_website/) · asiklarisstefanos@gmail.com
