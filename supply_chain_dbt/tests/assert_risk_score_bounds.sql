-- risk score should be between -3 and 3 for a healthy z-score distribution

select
    supplier_name,
    volatility_risk_score,
from {{ ref('agg_supplier_volatility') }}
where volatility_risk_score < -3 or volatility_risk_score > 3