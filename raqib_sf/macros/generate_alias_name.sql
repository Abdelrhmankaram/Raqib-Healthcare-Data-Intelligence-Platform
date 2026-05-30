{% macro generate_alias_name(custom_alias_name=none, node=none) -%}

    {%- if custom_alias_name is not none -%}
        {{ custom_alias_name | trim }}

    {%- elif node.fqn[2] == 'staging' -%}
        stg_{{ node.name | trim }}

    {%- elif node.fqn[2] == 'intermediate' -%}
        int_{{ node.name | trim }}

    {%- elif node.fqn[3] == 'dims' -%}
        dim_{{ node.name | trim }}

    {%- elif node.fqn[3] == 'fcts' -%}
        fct_{{ node.name | trim }}

    {%- else -%}
        {{ node.name | trim }}

    {%- endif -%}

{%- endmacro %}