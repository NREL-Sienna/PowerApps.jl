using Dash
using PowerSystems
using PowerSystemManager

include("component_tables.jl")

mutable struct Inputs
    system_path::Union{Nothing, String}
    system::Union{Nothing, System}
    default_units::Union{Nothing, String}
    component_types::Union{Nothing, Vector}
    component_type_options::Union{Nothing, Vector}
end

function Inputs()
    return Inputs(nothing, nothing, nothing, nothing, nothing)
end

inputs = Inputs()
inputs.default_units = "unknown"
inputs.component_types = []
inputs.component_type_options = []

function load_system()
    isnothing(inputs.system_path) && error("why is path nothing")
    inputs.system = System(inputs.system_path)
    inputs.default_units = get_units_base(inputs.system)
    inputs.component_types =
        [string(nameof(x)) for x in get_existing_component_types(inputs.system)]
    sort!(inputs.component_types)
    inputs.component_type_options =
        [Dict("label" => x, "value" => x) for x in inputs.component_types]
end

function get_component_table(component_type)
    return make_component_table(
        getproperty(PowerSystems, Symbol(component_type)),
        inputs.system,
    )
end

function get_default_component_type()
    isnothing(inputs.system) && return ""
    return string(nameof(typeof(first(get_components(Generator, inputs.system)))))
end

function make_datatable(component_type)
    isnothing(inputs.system) && return
    table = get_component_table(component_type)
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
            value = inputs.system_path,
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
                (label = "unknown", value = "unknown"),
                (label = "device_base", value = "device_base"),
                (label = "natural_units", value = "natural_units"),
                (label = "system_base", value = "system_base"),
            ],
            value = "unknown",
        ),
        html_div(id = "units_radio_output"),
    ],),
    html_br(),
    html_div([
        "Select a component type: ",
        dcc_radioitems(
            id = "component_type_dd",
            options = inputs.component_type_options,
            value = get_default_component_type(),
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
    n_clicks <= 0 && return loading_system, "Loaded system: None", "unknown", []
    if system_path != inputs.system_path
        inputs.system_path = system_path
        load_system()
    end

    return (
        loading_system,
        "Loaded system: $system_path\n$(summary(inputs.system))",
        get_units_base(inputs.system),
        inputs.component_type_options,
    )
end

callback!(
    app,
    Output("component_type_dd", "value"),
    Input("component_type_dd", "options"),
) do available_options
    return get_default_component_type()
end

callback!(
    app,
    Output("component_table_output", "children"),
    Input("units_radio", "value"),
    Input("component_type_dd", "value"),
) do units, component_type
    isnothing(inputs.system) && return
    units == "unknown" && return
    if get_units_base(inputs.system) != units
        set_units_base_system!(inputs.system, units)
    end
    make_datatable(component_type)
end

run_server(app, "0.0.0.0")
# run_server(app, "0.0.0.0", debug = true, dev_tools_hot_reload = true)
