# TODO:
# 3. add node size options on maps of none(default), load, generation capacity,

import Dates
import TimeSeries
import UUIDs
using Dash
using DataFrames
import InfrastructureSystems
using PowerSystems
import PowerSystemsMaps
import Plots
import PlotlyJS
using PowerApps

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
                                style = Dict("width" => "50%", "margin-left" => "10px"),
                            ),
                            html_button(
                                "Load System",
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
                                                    "margin-left" => "10px",
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
                            html_img(src = joinpath("assets", "logo.png"), height = "250"),
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
                        html_br(),
                        html_h1("Time Series View"),
                        html_h4("Selected component type:"),
                        html_div([
                            dcc_input(
                                readOnly = true,
                                value = "None",
                                id = "selected_component_type",
                                style = Dict("width" => "30%", "margin-left" => "10px"),
                            ),
                        ],),
                    ],
                    className = "column",
                ),
                html_div(
                    [
                        html_div([
                            html_br(),
                            html_img(src = joinpath("assets", "logo.png"), height = "75"),
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
            dcc_graph(id = "sts_plot"),
            html_hr(),
            html_div(
                [
                    dash_datatable(id = "deterministic_datatable"),
                    html_div(id = "deterministic_datatable_container"),
                ],
                style = Dict("color" => "black"),
            ),
            html_div([
                dcc_input(
                    id = "dts_step",
                    value = 1,
                    type = "number",
                    style = Dict("width" => "5%"),
                ),
                html_button(
                    "Plot Deterministic TimeSeries",
                    id = "plot_dts_button",
                    n_clicks = 0,
                    style = Dict("margin-left" => "10px"),
                ),
            ]),
            dcc_graph(id = "dts_plot"),
        ]),
    ],
)

map_tab = dcc_tab(
    label = "Maps",
    children = [
        html_div(
            [
                html_div(
                    [
                        html_br(),
                        html_h1("Map View"),
                        html_div([
                            dcc_input(
                                id = "shp_text",
                                value = "Enter the path of a shp file (optional)",
                                type = "text",
                                style = Dict("width" => "50%", "margin-left" => "10px"),
                            ),
                            html_button(
                                "Load Shapefile",
                                id = "load_shp_button",
                                n_clicks = 0,
                                style = Dict("margin-left" => "10px"),
                            ),
                        ]),
                        html_br(),
                        html_div(
                            [
                                html_div(
                                    [
                                        html_h3("Bus Style"),
                                        html_div(
                                            [
                                                html_h4(
                                                    "Hover:",
                                                    style = Dict("margin-left" => "5px"),
                                                ),
                                                dcc_radioitems(
                                                    id = "bus_hover_radio",
                                                    options = [
                                                        (label = "name", value = "name"),
                                                        (label = "full", value = "full"),
                                                        (label = "none", value = "none"),
                                                    ],
                                                    value = "name",
                                                    style = Dict(
                                                        "margin-left" => "3%",
                                                        "margin-top" => "15px",
                                                    ),
                                                    labelStyle = Dict(
                                                        "display" => "inline-block",
                                                    ),
                                                ),
                                            ],
                                            className = "row",
                                        ),
                                        html_div(
                                            [
                                                html_h4(
                                                    "Color:",
                                                    style = Dict("margin-left" => "5px"),
                                                ),
                                                dcc_radioitems(
                                                    id = "bus_color_radio",
                                                    options = [
                                                        (label = "area", value = "Area"),
                                                        (
                                                            label = "load_zone",
                                                            value = "LoadZone",
                                                        ),
                                                        (
                                                            label = "bustype",
                                                            value = "bustype",
                                                        ),
                                                        (
                                                            label = "base_voltage",
                                                            value = "base_voltage",
                                                        ),
                                                    ],
                                                    value = "Area",
                                                    style = Dict(
                                                        "margin-left" => "3%",
                                                        "margin-top" => "15px",
                                                    ),
                                                    labelStyle = Dict(
                                                        "display" => "inline-block",
                                                    ),
                                                ),
                                            ],
                                            className = "row",
                                        ),
                                        html_div(
                                            [
                                                html_div(
                                                    [
                                                        html_h4(
                                                            "α:",
                                                            style = Dict(
                                                                "textAlign" => "right",
                                                            ),
                                                        ),
                                                    ],
                                                    className = "column",
                                                ),
                                                html_div(
                                                    [
                                                        html_br(),
                                                        dcc_slider(
                                                            id = "bus_alpha",
                                                            min = 0.0,
                                                            max = 1.0,
                                                            step = 0.01,
                                                            value = 0.9,
                                                            dots = false,
                                                        ),
                                                    ],
                                                    className = "column",
                                                ),
                                            ],
                                            className = "row",
                                        ),
                                        html_div(
                                            [
                                                html_h4(
                                                    "Size:",
                                                    style = Dict("margin-left" => "5px"),
                                                ),
                                                dcc_radioitems(
                                                    id = "bus_size_scale",
                                                    options = [
                                                        (
                                                            label = "Generator",
                                                            value = "Generator",
                                                        ),
                                                        (
                                                            label = "ThermalGen",
                                                            value = "ThermalGen",
                                                        ),
                                                        (
                                                            label = "RenewableGen",
                                                            value = "RenewableGen",
                                                        ),
                                                        (
                                                            label = "StaticLoad",
                                                            value = "StaticLoad",
                                                        ),
                                                        (
                                                            label = "ControllableLoad",
                                                            value = "ControllableLoad",
                                                        ),
                                                        (
                                                            label = "base_voltage",
                                                            value = "base_voltage",
                                                        ),
                                                        (label = "none", value = "none"),
                                                    ],
                                                    value = "none",
                                                    style = Dict(
                                                        "margin-left" => "3%",
                                                        "margin-top" => "15px",
                                                    ),
                                                    labelStyle = Dict(
                                                        "display" => "inline-block",
                                                    ),
                                                ),
                                            ],
                                            className = "row",
                                        ),
                                        dcc_slider(
                                            id = "bus_size",
                                            min = 0.0,
                                            max = 15.0,
                                            step = 0.1,
                                            value = 2.0,
                                            dots = false,
                                            tooltip = Dict(
                                                "always_visible" => true,
                                                "placement" => "bottom",
                                            ),
                                        ),
                                    ],
                                    className = "two-thirds.column",
                                ),
                                html_div(
                                    [
                                        html_h3("Line Style"),
                                        html_div(
                                            [
                                                html_h4(
                                                    "Color:",
                                                    style = Dict("margin-left" => "5px"),
                                                ),
                                                dcc_radioitems(
                                                    id = "line_color_radio",
                                                    options = [
                                                        (label = "blue", value = "blue"),
                                                        (label = "red", value = "red"),
                                                        (label = "green", value = "green"),
                                                        (label = "white", value = "white"),
                                                    ],
                                                    value = "blue",
                                                    style = Dict(
                                                        "margin-left" => "3%",
                                                        "margin-top" => "15px",
                                                    ),
                                                    labelStyle = Dict(
                                                        "display" => "inline-block",
                                                    ),
                                                ),
                                            ],
                                            className = "row",
                                        ),
                                        html_div(
                                            [
                                                html_div(
                                                    [
                                                        html_h4(
                                                            "α:",
                                                            style = Dict(
                                                                "textAlign" => "right",
                                                            ),
                                                        ),
                                                    ],
                                                    className = "column",
                                                ),
                                                html_div(
                                                    [
                                                        html_br(),
                                                        dcc_slider(
                                                            id = "line_alpha",
                                                            min = 0.0,
                                                            max = 1.0,
                                                            step = 0.01,
                                                            value = 0.9,
                                                            dots = false,
                                                        ),
                                                    ],
                                                    className = "column",
                                                ),
                                            ],
                                            className = "row",
                                        ),
                                        html_h4(
                                            "Width:",
                                            style = Dict("margin-left" => "5px"),
                                        ),
                                        dcc_slider(
                                            id = "line_size",
                                            min = 0.0,
                                            max = 5.0,
                                            step = 0.1,
                                            value = 1.0,
                                            dots = false,
                                            tooltip = Dict(
                                                "always_visible" => true,
                                                "placement" => "bottom",
                                            ),
                                        ),
                                    ],
                                    className = "column",
                                ),
                            ],
                            className = "row",
                        ),
                    ],
                    className = "one-quarter.column",
                ),
                html_div(
                    [
                        html_div([
                            html_br(),
                            html_img(src = joinpath("assets", "logo.png"), height = "75"),
                        ],),
                        html_div([
                            html_button(
                                dcc_link(
                                    children = ["PowerSystemsMaps.jl"],
                                    href = "https://github.com/nrel-siip/powersystemsmaps.jl",
                                    target = "PowerSystemsMaps.jl",
                                ),
                                id = "maps_docs_button",
                                n_clicks = 0,
                                style = Dict("margin-top" => "10px"),
                            ),
                        ]),
                        html_br(),
                        html_button(
                            "Plot Map",
                            id = "plot_map_button",
                            n_clicks = 0,
                            style = Dict("margin-top" => "30px"),
                        ),
                    ],
                    className = "column",
                    style = Dict("textAlign" => "center", "width" => "25vw"),
                ),
            ],
            className = "row",
        ),
        html_div([
            html_hr(),
            dcc_graph(
                id = "map_plot",
                style = Dict("textAlign" => "center", "height" => "75vh"),
            ),
        ]),
    ],
)

# Note: This is only setup to support one worker. We would need to implement a backend
# process that manages a store and provides responses to each Dash worker. The code in this
# file would not be able to use any PSY functionality. There would have to be API calls
# to retrieve the data from the backend process.
g_data = SystemData()
get_system() = get_system(g_data)
app = dash(assets_folder = joinpath(pkgdir(PowerApps), "src", "assets"))
app.layout = html_div() do
    html_div([
        html_div(
            id = "app-page-header",
            children = [
                html_a(
                    id = "dashbio-logo",
                    href = "https://www.nrel.gov/",
                    target = "_blank",
                    children = [
                        html_img(src = joinpath("assets", "NREL-logo-green-tag.png")),
                    ],
                ),
                html_h2("PowerApps.jl"),
                html_a(
                    id = "gh-link",
                    children = ["View on GitHub"],
                    href = "https://github.com/NREL-SIIP/PowerApps.jl",
                    target = "_blank",
                    style = Dict("color" => "#d6d6d6", "border" => "solid 1px #d6d6d6"),
                ),
                html_img(src = joinpath("assets", "GitHub-Mark-Light-64px.png")),
            ],
            className = "app-page-header",
        ),
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
                    dcc_tab(
                        label = "Map",
                        children = [map_tab],
                        className = "custom-tab",
                        selected_className = "custom-tab--selected",
                    ),
                ],
                parent_className = "custom-tabs",
            ),
        ]),
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

function plot_ts(row_data, row_indexes, component_type, step = 1)
    traces = []
    for i in row_indexes
        row_index = i + 1  # julia is 1-based
        row = row_data[row_index]
        ts_name = row["name"]
        c_name = row["component_name"]
        ts_type = getproperty(PowerSystems, Symbol(row["type"]))
        c_type = getproperty(PowerSystems, Symbol(component_type))
        component = get_component(c_type, get_system(), c_name)
        ts = get_time_series(ts_type, component, ts_name)
        start_time =
            ts isa AbstractDeterministic ? get_forecast_initial_times(get_system())[step] :
            nothing
        ta = get_time_series_array(component, ts, start_time)
        trace = PlotlyJS.scatter(;
            x = TimeSeries.timestamp(ta),
            y = TimeSeries.values(ta),
            mode = "lines+markers",
            name = c_name,
        )
        push!(traces, trace)
    end
    layout = PlotlyJS.Layout(;
        title = "$component_type TimeSeries",
        xaxis_title = "Time",
        yaxis_title = "val",
    )
    return PlotlyJS.plot([x for x in traces], layout)
end

callback!(
    app,
    Output("sts_plot", "figure"),
    Input("plot_sts_button", "n_clicks"),
    Input("sts_datatable", "derived_viewport_selected_rows"),
    Input("sts_datatable", "derived_viewport_data"),
    State("selected_component_type", "value"),
) do n_clicks, row_indexes, row_data, component_type
    ctx = callback_context()
    if n_clicks < 1 ||
       length(ctx.triggered) == 0 ||
       ctx.triggered[1].prop_id != "plot_sts_button.n_clicks" ||
       isnothing(row_indexes) ||
       isempty(row_indexes)
        throw(PreventUpdate())
    end
    return plot_ts(row_data, row_indexes, component_type)
end


callback!(
    app,
    Output("dts_plot", "figure"),
    Input("plot_dts_button", "n_clicks"),
    Input("deterministic_datatable", "derived_viewport_selected_rows"),
    Input("deterministic_datatable", "derived_viewport_data"),
    Input("dts_step", "value"),
    State("selected_component_type", "value"),
) do n_clicks, row_indexes, row_data, step, component_type
    ctx = callback_context()
    if n_clicks < 1 ||
       length(ctx.triggered) == 0 ||
       ctx.triggered[1].prop_id != "plot_dts_button.n_clicks" ||
       isnothing(row_indexes) ||
       isempty(row_indexes)
        throw(PreventUpdate())
    end
    return plot_ts(row_data, row_indexes, component_type, step)
end



function plotlyjs_syncplot(plt::Plots.Plot{Plots.PlotlyJSBackend})
    plt[:overwrite_figure] && Plots.closeall()
    plt.o = PlotlyJS.plot()
    traces = PlotlyJS.GenericTrace[]
    for series_dict in Plots.plotly_series(plt)
        filter!(p -> !(isa(last(p), Number) && isnan(last(p))), series_dict)
        plotly_type = pop!(series_dict, :type)
        series_dict[:transpose] = false
        push!(traces, PlotlyJS.GenericTrace(plotly_type; series_dict...))
    end
    PlotlyJS.addtraces!(plt.o, traces...)
    layout = Dict([
        p for p in Plots.plotly_layout(plt) if first(p) ∉ [:xaxis, :yaxis, :height, :width]
    ])
    layout[:xaxis_visible] = false
    layout[:yaxis_visible] = false
    PlotlyJS.relayout!(plt.o, layout)
    return plt.o
end

function name_components(comp, hover)
    if hover == "name"
        names = get_name.(comp)
    elseif hover == "full"
        names = string.(comp)
    else
        names = ["" for c in comp]
    end
    return names
end

callback!(
    app,
    Output("map_plot", "figure"),
    Input("plot_map_button", "n_clicks"),
    Input("load_shp_button", "n_clicks"),
    Input("bus_hover_radio", "value"),
    Input("bus_color_radio", "value"),
    Input("bus_alpha", "value"),
    Input("bus_size_scale", "value"),
    Input("bus_size", "value"),
    Input("line_color_radio", "value"),
    Input("line_alpha", "value"),
    Input("line_size", "value"),
    State("shp_text", "value"),
) do n_clicks,
n_shp_clicks,
bus_hover,
color_field,
bus_alpha,
bus_scale,
bus_size,
line_color,
line_alpha,
line_size,
shp_txt
    n_clicks < 1 && throw(PreventUpdate())

    if n_shp_clicks > 0
        shp_path = shp_txt
    else
        shp_path = joinpath(
            pkgdir(PowerApps),
            "src",
            "assets",
            "world-administrative-boundaries",
            "world-administrative-boundaries.shp",
        )
    end

    if endswith(shp_path, ".shp")
        # load a shapefile
        shp = PowerSystemsMaps.Shapefile.shapes(PowerSystemsMaps.Shapefile.Table(shp_path))
        shp = PowerSystemsMaps.lonlat_to_webmercator(shp) #adjust coordinates

        # plot a map from shapefile
        p = Plots.plot(
            shp,
            fillcolor = "grey",
            background_color = "#1E1E1E",
            linecolor = "darkgrey",
            axis = nothing,
            grid = false,
            border = :none,
            label = "",
            legend_font_color = :red,
        )
    else
        p = Plots.plot(background_color = "black", axis = nothing, border = :none)
    end

    if !isnothing(get_system())
        system = get_system()
        c =
            color_field ∈ ["Area", "LoadZone"] ?
            IS.get_type_from_strings(PSY, color_field) : Symbol(color_field)

        buses = get_components(Bus, system)
        node_hover_str = name_components(buses, bus_hover)

        if bus_scale == "base_voltage"
            node_size = getfield.(buses, :base_voltage)
        elseif bus_scale == "none"
            node_size = ones(length(buses))
        else
            category = IS.get_type_from_strings(PSY, bus_scale)
            node_size = zeros(length(buses))
            for (ix, bus) in enumerate(buses)
                injectors = get_components(
                    x -> get_available(x) && get_bus(x) == bus,
                    category,
                    system,
                )
                isempty(injectors) && continue
                node_size[ix] = sum(get_max_active_power.(injectors))
            end
        end

        g = PowerSystemsMaps.make_graph(system, K = 0.01, color_by = c)
        p = PowerSystemsMaps.plot_net!(
            p,
            g,
            nodesize = node_size .* bus_size,
            nodehover = node_hover_str,
            linecolor = line_color,
            linewidth = line_size,
            linealpha = line_alpha,
            nodealpha = bus_alpha,
            lines = true,
            shownodelegend = true,
        )
    end
    plotlyjs_syncplot(p)
    Plots.backend_object(p)
end

function run_system_explorer(; port = 8050)
    @info("Navigate browser to: http://0.0.0.0:$port")
    if !isnothing(get(ENV, "SIIP_DEBUG", nothing))
        run_server(app, "0.0.0.0", port, debug = true, dev_tools_hot_reload = true)
    else
        run_server(app, "0.0.0.0", port)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_system_explorer()
end
