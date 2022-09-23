import Dates
import TimeSeries
import UUIDs
using Dash
using DataFrames
using PlotlyJS
import InfrastructureSystems
using PowerSystems
using PowerSystemManager

const IS = InfrastructureSystems
const PSY = PowerSystems
const DEFAULT_UNITS = "unknown"

include("utils.jl")
include("component_tables.jl")

mutable struct SystemData
    system::Union{Nothing,System}
end

SystemData() = SystemData(nothing)
get_system(data::SystemData) = data.system

function get_component_table(sys, component_type)
    return make_component_table(getproperty(PowerSystems, Symbol(component_type)), sys)
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
    components = get_component_table(sys, component_type)
    columns = make_table_columns(components)
    return (
        dash_datatable(
            id = "components_datatable",
            columns = columns,
            data = components,
            editable = false,
            filter_action = "native",
            sort_action = "native",
            row_selectable = "multi",
            selected_rows = [],
            style_table = Dict("height" => 400),
            style_data = Dict(
                "width" => "100px",
                "minWidth" => "100px",
                "maxWidth" => "100px",
                "overflow" => "hidden",
                "textOverflow" => "ellipsis",
            ),
        ),
        components,
    )
end

system_tab = dcc_tab(
    label = "System",
    children = [
        html_div(
            [
                html_div(
                    [
                        html_br(),
                        html_h1("System View"),
                        html_div([
                            dcc_input(
                                id = "system_text",
                                value = "Enter the path of a system file",
                                type = "text",
                                style = Dict("width" => "50%"),
                            ),
                            html_button(
                                "Load system",
                                id = "load_button",
                                n_clicks = 0,
                                style = Dict("margin-left" => "10px"),
                            ),
                        ]),
                        html_br(),
                        html_div([
                            html_div(
                                [
                                    html_div(
                                        [
                                            html_h5("Loaded system"),
                                            dcc_textarea(
                                                readOnly = true,
                                                value = "None",
                                                style = Dict(
                                                    "width" => "100%",
                                                    "height" => 100,
                                                    "margin-left" => "3%",
                                                ),
                                                id = "load_description",
                                            ),
                                        ],
                                        className = "column",
                                    ),
                                    html_div(
                                        [
                                            html_h5("Select units base"),
                                            dcc_radioitems(
                                                id = "units_radio",
                                                options = [
                                                    (
                                                        label = DEFAULT_UNITS,
                                                        value = DEFAULT_UNITS,
                                                        disabled = true,
                                                    ),
                                                    (
                                                        label = "device_base",
                                                        value = "device_base",
                                                    ),
                                                    (
                                                        label = "natural_units",
                                                        value = "natural_units",
                                                    ),
                                                    (
                                                        label = "system_base",
                                                        value = "system_base",
                                                    ),
                                                ],
                                                value = DEFAULT_UNITS,
                                                style = Dict("margin-left" => "3%"),
                                            ),
                                        ],
                                        className = "column",
                                    ),
                                ],
                                className = "row",
                            ),
                        ]),
                        html_div([
                            dcc_loading(
                                id = "loading_system",
                                type = "default",
                                children = [html_div(id = "loading_system_output")],
                            ),
                        ]),
                        html_br(),
                        html_div(
                            [
                                html_div(
                                    [
                                        html_h5("Selet a component type"),
                                        dcc_radioitems(
                                            id = "component_type_radio",
                                            options = [],
                                            value = "",
                                            style = Dict("margin-left" => "3%"),
                                        ),
                                    ],
                                    className = "column",
                                ),
                                html_div(
                                    [
                                        html_h5("Number of components: "),
                                        dcc_input(
                                            id = "num_components_text",
                                            value = "0",
                                            type = "text",
                                            readOnly = true,
                                            style = Dict("margin-left" => "3%"),
                                        ),
                                    ],
                                    className = "column",
                                ),
                            ],
                            className = "row",
                        ),
                    ],
                    className = "column",
                ),
                html_div(
                    [
                        html_div([
                            html_br(),
                            html_img(src = "assets/logo.png", height = "250"),
                        ],),
                        html_div([
                            html_button(
                                dcc_link(
                                    children = ["PowerSystems.jl Docs"],
                                    href = "https://nrel-siip.github.io/PowerSystems.jl/stable/",
                                    target = "PowerSystems.jl Docs",
                                ),
                                id = "docs_button",
                                n_clicks = 0,
                                style = Dict("margin-top" => "10px"),
                            ),
                        ]),
                    ],
                    className = "column",
                    style = Dict("textAlign" => "center"),
                ),
            ],
            className = "row",
        ),
        html_br(),
        # TODO: delay displaying this table until the system is loaded
        html_h3("Components Table"),
        html_div(
            [
                dash_datatable(id = "components_datatable"),
                html_div(id = "components_datatable_container"),
            ],
            style = Dict("color" => "black"),
        ),
    ],
)

component_tab = dcc_tab(
    label = "Time Series",
    children = [
        html_div(
            [
                html_div(
                    [
                        html_h1("Time Series View"),
                        html_h4("Selected component type:"),
                        html_div([
                            dcc_input(
                                readOnly = true,
                                value = "None",
                                id = "selected_component_type",
                                style = Dict("width" => "30%", "margin-left" => "3%"),
                            ),
                        ],),
                    ],
                    className = "column",
                ),
                html_div(
                    [
                        html_div([
                            html_br(),
                            html_img(src = "assets/logo.png", height = "75"),
                        ],),
                        html_div([
                            html_button(
                                dcc_link(
                                    children = ["PowerSystems.jl Docs"],
                                    href = "https://nrel-siip.github.io/PowerSystems.jl/stable/",
                                    target = "PowerSystems.jl Docs",
                                ),
                                id = "another_docs_button",
                                n_clicks = 0,
                                style = Dict("margin-top" => "10px"),
                            ),
                        ]),
                    ],
                    className = "column",
                    style = Dict("textAlign" => "center"),
                ),
            ],
            className = "row",
        ),
        html_br(),
        html_div([
            html_h4("Select time series:"),
            html_div(
                [
                    dash_datatable(id = "sts_datatable"),
                    html_div(id = "sts_datatable_container"),
                ],
                style = Dict("color" => "black"),
            ),
            html_br(),
            html_button("Plot SingleTimeSeries", id = "plot_sts_button", n_clicks = 0),
            html_hr(),
            html_div(
                [
                    dash_datatable(id = "deterministic_datatable"),
                    html_div(id = "deterministic_datatable_container"),
                ],
                style = Dict("color" => "black"),
            ),
            dcc_graph(id = "sts_plot"),
        ]),
    ],
)

# Note: This is only setup to support one worker. We would need to implement a backend
# process that manages a store and provides responses to each Dash worker. The code in this
# file would not be able to use any PSY functionality. There would have to be API calls
# to retrieve the data from the backend process.
g_data = SystemData()
get_system() = get_system(g_data)
app = dash()
app.layout = html_div() do
    html_div([
        dcc_tabs(
            [
                dcc_tab(
                    label = "System",
                    children = [system_tab],
                    className = "custom-tab",
                    selected_className = "custom-tab--selected",
                ),
                dcc_tab(
                    label = "Time Series",
                    children = [component_tab],
                    className = "custom-tab",
                    selected_className = "custom-tab--selected",
                ),
            ],
            parent_className = "custom-tabs",
        ),
    ])
end

callback!(
    app,
    Output("loading_system_output", "children"),
    Output("load_description", "value"),
    Output("units_radio", "value"),
    Output("component_type_radio", "options"),
    Input("loading_system", "children"),
    Input("load_button", "n_clicks"),
    State("system_text", "value"),
    State("load_description", "value"),
) do loading_system, n_clicks, system_path, load_description
    n_clicks <= 0 && throw(PreventUpdate())
    system = System(system_path, time_series_read_only = true)
    g_data.system = system
    return (
        loading_system,
        "$system_path\n$(summary(system))",
        get_system_units(system),
        get_component_type_options(system),
    )
end

callback!(
    app,
    Output("component_type_radio", "value"),
    Input("component_type_radio", "options"),
) do available_options
    isnothing(get_system()) && throw(PreventUpdate())
    return get_default_component_type(get_system())
end

callback!(
    app,
    Output("components_datatable_container", "children"),
    Output("num_components_text", "value"),
    Input("units_radio", "value"),
    Input("component_type_radio", "value"),
) do units, component_type
    (units == "" || component_type == "") && throw(PreventUpdate())
    system = get_system()
    @assert !isnothing(system)
    @assert units != DEFAULT_UNITS
    if get_system_units(system) != units
        set_units_base_system!(system, units)
    end
    table, components = make_datatable(system, component_type)
    return table, string(length(components))
end

callback!(
    app,
    Output("selected_component_type", "value"),
    Output("sts_datatable_container", "children"),
    Output("deterministic_datatable_container", "children"),
    Input("components_datatable", "derived_viewport_selected_rows"),
    Input("components_datatable", "derived_viewport_data"),
    State("component_type_radio", "value"),
) do row_indexes, row_data, component_type
    if (isnothing(row_indexes) || isempty(row_indexes) || isnothing(row_indexes[1]))
        throw(PreventUpdate())
    end
    static_time_series = []
    deterministic_time_series = []
    for i in row_indexes
        row_index = i + 1  # julia is 1-based
        row = row_data[row_index]
        component_name = row["name"]
        type = getproperty(PowerSystems, Symbol(component_type))
        component = get_component(type, get_system(), component_name)
        component_text = "$component_type $component_name"

        if has_time_series(component)
            for metadata in IS.list_time_series_metadata(component)
                ts_type = IS.time_series_metadata_to_data(metadata)
                if ts_type <: StaticTimeSeries
                    push!(
                        static_time_series,
                        OrderedDict(
                            "component_name" => component_name,
                            "type" => string(nameof(ts_type)),
                            "name" => get_name(metadata),
                            "resolution" => string(Dates.Minute(get_resolution(metadata))),
                            "initial_timestamp" =>
                                string(IS.get_initial_timestamp(metadata)),
                            "length" => IS.get_length(metadata),
                            "scaling_factor_multiplier" =>
                                string(IS.get_scaling_factor_multiplier(metadata)),
                        ),
                    )
                elseif ts_type <: AbstractDeterministic
                    push!(
                        deterministic_time_series,
                        OrderedDict(
                            "component_name" => component_name,
                            "type" => string(nameof(ts_type)),
                            "name" => get_name(metadata),
                            "resolution" => string(Dates.Minute(get_resolution(metadata))),
                            "initial_timestamp" =>
                                string(IS.get_initial_timestamp(metadata)),
                            "interval" => string(IS.get_horizon(metadata)),
                            "count" => IS.get_count(metadata),
                            "horizon" => IS.get_horizon(metadata),
                            "scaling_factor_multiplier" =>
                                string(IS.get_scaling_factor_multiplier(metadata)),
                        ),
                    )
                end
            end
            sort!(static_time_series, by = x -> x["name"])
        end
    end

    sts_columns = make_table_columns(static_time_series)
    style_data = Dict(
        "width" => "100px",
        "minWidth" => "100px",
        "maxWidth" => "100px",
        "overflow" => "hidden",
        "textOverflow" => "ellipsis",
    )
    sts_table = dash_datatable(
        id = "sts_datatable",
        columns = sts_columns,
        data = static_time_series,
        editable = false,
        filter_action = "native",
        sort_action = "native",
        row_selectable = isempty(static_time_series) ? nothing : "multi",
        selected_rows = [],
        style_data = style_data,
    )
    deterministic_columns = make_table_columns(deterministic_time_series)
    deterministic_table = dash_datatable(
        id = "deterministic_datatable",
        columns = deterministic_columns,
        data = deterministic_time_series,
        editable = false,
        filter_action = "native",
        sort_action = "native",
        row_selectable = isempty(deterministic_time_series) ? nothing : "multi",
        selected_rows = [],
        style_data = style_data,
    )

    return component_type, sts_table, deterministic_table
end

callback!(
    app,
    Output("sts_plot", "figure"),
    Input("plot_sts_button", "n_clicks"),
    Input("sts_datatable", "derived_viewport_selected_rows"),
    Input("sts_datatable", "derived_viewport_data"),
    State("selected_component_type", "value"),
) do n_clicks, row_indexes, row_data, component_type
    n_clicks < 1 && throw(PreventUpdate())
    traces = []
    for i in row_indexes
        row_index = i + 1  # julia is 1-based
        row = row_data[row_index]
        ts_name = row["name"]
        ts_type = getproperty(PowerSystems, Symbol(row["type"]))
        c_name = row["component_name"]
        c_type = getproperty(PowerSystems, Symbol(component_type))
        component = get_component(c_type, get_system(), c_name)
        ta = get_time_series_array(ts_type, component, ts_name)
        trace = scatter(;
            x = TimeSeries.timestamp(ta),
            y = TimeSeries.values(ta),
            mode = "lines+markers",
            name = c_name,
        )
        push!(traces, trace)
    end
    layout = Layout(;
        title = "$component_type SingleTimeSeries",
        xaxis_title = "Time",
        yaxis_title = "val",
    )
    return plot([x for x in traces], layout)
end

if !isnothing(get(ENV, "SIIP_DEBUG", nothing))
    run_server(app, "0.0.0.0", debug = true, dev_tools_hot_reload = true)
else
    run_server(app, "0.0.0.0")
end
