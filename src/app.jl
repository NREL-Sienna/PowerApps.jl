using Dash
using PowerSystems
using PowerSystemManager

include("component_tables.jl")

const DEFAULT_UNITS = "unknown"

system = nothing

function get_component_table(sys, component_type)
    return make_component_table(
        getproperty(PowerSystems, Symbol(component_type)),
        sys,
    )
end

function get_default_component_type(sys)
    return string(nameof(typeof(first(get_components(Generator, sys)))))
end

function get_component_type_options(sys)
    component_types = [string(nameof(x)) for x in get_existing_component_types(sys)]
    sort!(component_types)
    return [Dict("label" => x, "value" => x) for x in component_types]
end

function get_system_units(sys)
    return lowercase(get_units_base(sys))
end

function make_datatable(sys, component_type)
    table = get_component_table(sys, component_type)
    columns = []
    for (name, val) in first(table)
        if val isa AbstractString
            type = "text"
        elseif val isa Number
            type = "numeric"
        else
            error("Unsupported type: $(val): $(typeof(val))")
        end
        push!(columns, Dict("name" => name, "id" => name, "type" => type))
    end

    return dash_datatable(
        columns = columns,
        data = table,
        editable = true,
        filter_action = "native",
        sort_action = "native",
        style_table = Dict("height" => 400),
        style_data = Dict(
            "width" => "100px",
            "minWidth" => "100px",
            "maxWidth" => "100px",
            "overflow" => "hidden",
            "textOverflow" => "ellipsis",
        ),
    )
end

app = dash()

app.layout = html_div() do
    html_h1("Power Systems Viewer"),
    html_div([
        "Enter the path of a system file: ",
        dcc_input(
            id = "system_text",
            value = "",
            type = "text",
            style = Dict("width" => "25%"),
        ),
        html_button(
            "Load system",
            id = "load_button",
            n_clicks = 0,
            style = Dict(
                "font-size" => "12px",
                "width" => "100px",
                "display" => "inline-block",
                "margin-bottom" => "10px",
                "margin-right" => "5px",
                "height" => "37px",
                "verticalAlign" => "top",
            ),
        ),
        html_div(id = "system_text_output"),
    ],),
    html_div([
        dcc_textarea(
            readOnly = true,
            value = "Loaded system: None",
            style = Dict("width" => "25%", "height" => 40),
            id = "load_description",
        ),
        html_div(id = "load_description_output"),
    ]),
    html_div([
        dcc_loading(
            id = "loading_system",
            type = "default",
            children = [html_div(id = "loading_system_output")],
        ),
    ]),
    html_br(),
    html_div([
        "Select units base: ",
        dcc_radioitems(
            id = "units_radio",
            options = [
                (label = DEFAULT_UNITS, value = DEFAULT_UNITS, disabled = true),
                (label = "device_base", value = "device_base"),
                (label = "natural_units", value = "natural_units"),
                (label = "system_base", value = "system_base"),
            ],
            value = DEFAULT_UNITS,
        ),
        html_div(id = "units_radio_output"),
    ],),
    html_br(),
    html_div([
        "Select a component type: ",
        dcc_radioitems(
            id = "component_type_dd",
            options = [],
            value = "",
        ),
        html_div(id = "component_type_dd_output"),
    ]),
    html_br(),
    html_h3("Components Table"),
    html_div(id = "component_table_output")
end

callback!(
    app,
    Output("loading_system_output", "children"),
    Output("load_description", "value"),
    Output("units_radio", "value"),
    Output("component_type_dd", "options"),
    Input("loading_system", "children"),
    Input("load_button", "n_clicks"),
    State("system_text", "value"),
    State("load_description", "value"),
) do loading_system, n_clicks, system_path, load_description
    global system
    n_clicks <= 0 && return loading_system, "Loaded system: None", DEFAULT_UNITS, []
        system = System(system_path)

    return (
        loading_system,
        "Loaded system: $system_path\n$(summary(system))",
        get_system_units(system),
        get_component_type_options(system),
    )
end

callback!(
    app,
    Output("component_type_dd", "value"),
    Input("component_type_dd", "options"),
) do available_options
    isnothing(system) && return ""
    return get_default_component_type(system)
end

callback!(
    app,
    Output("component_table_output", "children"),
    Input("units_radio", "value"),
    Input("component_type_dd", "value"),
) do units, component_type
    isnothing(system) && return
    @assert units != DEFAULT_UNITS
    if get_system_units(system) != units
        set_units_base_system!(system, units)
    end
    make_datatable(system, component_type)
end

if !isnothing(get(ENV, "PSY_VIEWER_DEBUG", nothing))
    run_server(app, "0.0.0.0", debug = true, dev_tools_hot_reload = true)
else
    run_server(app, "0.0.0.0")
end
