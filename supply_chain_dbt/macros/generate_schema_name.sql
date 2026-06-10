{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {%- if custom_schema_name | upper | trim == 'RAW' -%}
            RAW
        {%- else -%}
            {{ target.schema }}_{{ custom_schema_name | upper | trim }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}