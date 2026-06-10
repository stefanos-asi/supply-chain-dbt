{% macro weighted_composite(z_rev, z_def, z_lead, z_vel, w_rev=0.30, w_def=0.30, w_lead=0.20, w_vel=0.20) %}
    (
        {{ z_rev }}  * {{ w_rev }} +
        {{ z_def }}  * {{ w_def }} +
        {{ z_lead }} * {{ w_lead }} +
        {{ z_vel }}  * {{ w_vel }}
    )
{% endmacro %}