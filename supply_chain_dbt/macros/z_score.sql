{% macro z_score(value, mean, std_dev) %}
    CASE
        WHEN {{ std_dev }} = 0 OR {{ std_dev }} IS NULL THEN 0
        ELSE ({{ value }} - {{ mean }}) / {{ std_dev }}
    END
{% endmacro %}