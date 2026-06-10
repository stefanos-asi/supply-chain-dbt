{% macro risk_category(score_column) %}
    CASE
        WHEN {{ score_column }} > 1.5  THEN 'CRITICAL VOLATILITY'
        WHEN {{ score_column }} > 0.5  THEN 'HIGH VOLATILITY'
        WHEN {{ score_column }} > -0.5 THEN 'MODERATE'
        ELSE 'STABLE'
    END
{% endmacro %}