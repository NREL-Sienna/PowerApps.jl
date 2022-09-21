import UUIDs
using Dash
import JSON3
using PowerSystemManager
import PowerSystems
import PowerSimulations
using PowerSystemManager

const PSI = PowerSimulations
const PSY = PowerSystems

import PowerSimulations.Api: from_json, to_json

include("utils.jl")

const DEFAULT_POWER_MODEL = "CopperPlatePowerModel"

function make_decision_model()
    return Dict(
        "decision_problem_type" => DECISION_PROBLEM_TYPES[1]["value"],
        "name" => "",
        "template" => Dict(
            "network" => Dict("network_type" => DEFAULT_POWER_MODEL),
            "devices" => [],
            "services" => [],
        ),
        "system_path" => "",
        "optimizer" => nothing,
    )
end

PSI.Api.initialize_api_types()

const IC_CHRONOLOGY_OPTIONS = make_widget_options(
    PSI.Api.from_json(Dict, PSI.Api.list_types("InitialConditionChronologies"))["types"],
)
const OPTIMIZER_OPTIONS =
    make_widget_options(PSI.Api.from_json(Dict, PSI.Api.list_types("Optimizers"))["types"])
const NETWORK_TYPES =
    make_widget_options(PSI.Api.from_json(Dict, PSI.Api.list_types("PowerModels"))["types"])
@assert DEFAULT_POWER_MODEL in (x["value"] for x in NETWORK_TYPES)
const DECISION_PROBLEM_TYPES = make_widget_options(
    PSI.Api.from_json(Dict, PSI.Api.list_types("DecisionProblems"))["types"],
)

decision_model_tab = dcc_tab(
    label="Decision Model",
    value="tab-1",
    children=[
        html_h1("Make Decision Model"),
        html_div([
            "Name: ",
            dcc_input(
                id="dm_name_text",
                value="",
                type="text",
                style=Dict("width" => "10%"),
            ),
        ]),
        html_br(),
        html_div([
            "Enter the path of a system file: ",
            dcc_input(
                id="system_path_text",
                value="",
                type="text",
                style=Dict("width" => "25%"),
            ),
            html_button("Load system", id="dm_load_button", n_clicks=0),
            html_div(id="dm_system_text_output"),
            dcc_input(
                readOnly=true,
                value="Loaded system: None",
                id="dm_load_description",
                style=Dict("width" => "25%"),
            ),
            html_br(),
        ],),
        html_div([
            dcc_loading(
                id="dm_loading_system",
                type="default",
                children=[html_div(id="dm_loading_system_output")],
            ),
        ]),
        html_br(),
        html_button("Reset decision model", id="reset_decision_button", n_clicks=0),
        html_br(),
        html_div([
            "Select an optimizer:",
            dcc_radioitems(
                id="optimizer_radio",
                options=OPTIMIZER_OPTIONS,
                value=OPTIMIZER_OPTIONS[1]["value"],
            ),
            html_div(id="optimizer_radio_output"),
        ],),
        html_div([
            dcc_textarea(
                value="",
                style=Dict("width" => "50%", "height" => 60),
                id="optimizer_settings_text",
            ),
            html_div(id="optimizer_settings_text_output"),
            html_button("Add optimizer", id="add_optimizer_button", n_clicks=0),
        ]),
        html_br(),
        html_div([
            html_div([
                "Select decision problem type:",
                dcc_radioitems(
                    id="decision_problems_radio",
                    options=DECISION_PROBLEM_TYPES,
                    value=DECISION_PROBLEM_TYPES[1]["value"],
                ),
            ]),
            html_h3("Problem Template"),
            "Select network type:",
            dcc_dropdown(
                id="network_type_radio_dd",
                options=NETWORK_TYPES,
                value="CopperPlatePowerModel",
            ),
            html_br(),
            html_div([
                "Select device type:",
                dcc_radioitems(id="device_type_radio", options=[], value=""),
                html_br(),
                "Select device formulation:",
                dcc_radioitems(id="device_formulation_radio", options=[], value=""),
                html_br(),
                html_button("Add device model", id="add_device_model_button", n_clicks=0),
                html_button(
                    "Remove device model",
                    id="remove_device_model_button",
                    n_clicks=0,
                ),
            ]),
            dcc_markdown("", id="unassigned_dev_types_md"),
        ],),
        html_br(),
        html_h4("Current Decision Model Content"),
        dcc_markdown(
            insert_json_text_in_markdown(to_json(Dict())),
            id="decision_model_text",
        ),
        html_div(id="decision_model_text_output"),
        html_button("Save decision model", id="save_decision_model_button", n_clicks=0),
        html_br(),
        html_h4("Saved Decision Models"),
        dcc_input(
            value="",
            style=Dict("width" => "50%"),
            id="saved_decision_model_text",
            readOnly=true,
        ),
    ],
)

simulation_tab = dcc_tab(
    label="Simulation",
    value="tab-2",
    children=[
        html_h1("Make Simulation"),
        html_div([
            "Name: ",
            dcc_input(
                id="sim_name_text",
                value="",
                type="text",
                style=Dict("width" => "10%"),
            ),
        ]),
        html_br(),
        html_div([
            "Num steps: ",
            dcc_input(
                id="num_steps_text",
                value="1",
                type="text",
                style=Dict("width" => "5%"),
            ),
        ]),
        html_div([
            html_h4("Simulation Sequence"),
            "Select an initial condition chronology:",
            dcc_radioitems(
                id="ic_chron_radio",
                options=IC_CHRONOLOGY_OPTIONS,
                value=IC_CHRONOLOGY_OPTIONS[1]["value"],
            ),
        ]),
        html_br(),
        html_div([
            "Select one or more decision models:",
            dcc_checklist(id="decision_models_checklist", options=[], value=[]),
        ]),
        html_br(),
        html_button("Create simulation", id="create_sim_button", n_clicks=0),
        html_h4("Simulation Content"),
        html_div([dcc_markdown("", id="simulation_text")]),
        dcc_clipboard(
            target_id="simulation_text",
            title="copy",
            style=Dict(
                "display" => "inline-block",
                "fontSize" => 20,
                "verticalAlign" => "top",
            ),
        ),
    ],
)

app = dash()
app.layout = html_div() do
    # TODO: There is a better way to lay out the GUI components. Should probably
    # show the simulation tab first and have a create-decision-model button that
    # dynamically renders the decision model tab.
    html_div([
        dcc_tabs(
            id="tabs_component",
            value="tab-1",
            children=[decision_model_tab, simulation_tab],
        ),
        dcc_store(id="saved_decision_models"),
        dcc_store(id="dm_formulations"),
    ])
end

function add_device_model!(decision_model, type, formulation)
    found = false
    for model in decision_model["template"]["devices"]
        if model["device_type"] == type && model["formulation"] == formulation
            found = true
        end
    end
    if !found
        push!(
            decision_model["template"]["devices"],
            Dict("device_type" => type, "formulation" => formulation),
        )
    end
end

function remove_device_model!(decision_model, type, formulation)
    for (i, model) in enumerate(decision_model["template"]["devices"])
        if model["device_type"] == type && model["formulation"] == formulation
            deleteat!(decision_model["template"]["devices"], i)
            break
        end
    end
end

function make_unassigned_type_md(category, decision_model, types)
    unassigned_types = setdiff(
        types,
        Set([x["$(category)_type"] for x in decision_model["template"]["$(category)s"]]),
    )
    if isempty(unassigned_types)
        return "All $category types are assigned"
    end

    unassigned_text = """
    ### Unassigned $category types
    """
    for type in unassigned_types
        unassigned_text *= "- $type\n"
    end

    return unassigned_text
end

callback!(
    app,
    Output("dm_loading_system_output", "children"),
    Output("dm_load_description", "value"),
    Output("dm_formulations", "data"),
    Output("device_type_radio", "options"),
    Input("dm_loading_system", "children"),
    Input("dm_load_button", "n_clicks"),
    State("system_path_text", "value"),
) do loading_system, n_clicks, system_path
    n_clicks < 1 && throw(PreventUpdate())
    system = PSY.System(system_path, time_series_read_only=true)
    formulations = PSI.Api.get_available_formulations(system)
    device_forms_by_type =
        PSI.Api.from_json(Dict, PSI.Api.list_device_formulations_by_type(formulations))["formulations_by_type"]
    device_types = [x["device_type"] for x in device_forms_by_type]
    device_forms = device_forms_by_type[1]["formulations"]
    # service_models = list_service_models(dm_formulations)
    # In theory we could set device type labels in a different color until they've been
    # added. The docs for python cover this but not for julia. And the python example
    # doesn't seem to work in julia.
    return (
        loading_system,
        "Loaded system: $system_path",
        formulations,
        make_widget_options(device_types),
    )
end

callback!(
    app,
    Output("device_type_radio", "value"),
    Input("device_type_radio", "options"),
) do options
    isempty(options) && return ""
    return options[1]["value"]
end

callback!(
    app,
    Output("device_formulation_radio", "options"),
    Input("device_type_radio", "value"),
    Input("dm_formulations", "data"),
) do device_type, dm_formulations
    device_type == "" && throw(PreventUpdate())
    forms = from_json(Dict, dm_formulations)
    device_forms_by_type =
        PSI.Api.from_json(Dict, PSI.Api.list_device_formulations_by_type(dm_formulations))["formulations_by_type"]
    for item in device_forms_by_type
        if item["device_type"] == device_type
            return make_widget_options(item["formulations"])
        end
    end

    error("BUG: did not find device_type=$device_type")
end

callback!(
    app,
    Output("device_formulation_radio", "value"),
    Input("device_formulation_radio", "options"),
) do options
    isempty(options) && throw(PreventUpdate())
    return options[1]["value"]
end

callback!(
    app,
    Output("optimizer_settings_text", "value"),
    Input("optimizer_radio", "value"),
) do optimizer
    optimizer == "" && throw(PreventUpdate())
    to_json(from_json(Dict, PSI.Api.get_default_optimizer_settings(optimizer)), indent=2)
end

callback!(
    app,
    Output("unassigned_dev_types_md", "children"),
    Output("decision_model_text", "children"),
    Input("reset_decision_button", "n_clicks"),
    Input("add_device_model_button", "n_clicks"),
    Input("remove_device_model_button", "n_clicks"),
    Input("add_optimizer_button", "n_clicks"),
    State("system_path_text", "value"),
    State("dm_name_text", "value"),
    State("decision_problems_radio", "value"),
    State("network_type_radio_dd", "value"),
    State("device_type_radio", "options"),
    State("device_type_radio", "value"),
    State("device_formulation_radio", "value"),
    State("optimizer_radio", "value"),
    State("optimizer_settings_text", "value"),
    State("decision_model_text", "children"),
) do n_clicks1,
n_clicks2,
n_clicks3,
n_clicks4,
system_path,
name,
decision_problem_type,
network_type,
device_type_options,
device_type,
device_formulation,
optimizer,
optimizer_settings,
decision_model_text
    ctx = callback_context()
    if length(ctx.triggered) == 0
        throw(PreventUpdate())
    end
    decision_model = from_json(Dict, get_json_text_from_markdown(decision_model_text))
    if isempty(decision_model)
        decision_model = make_decision_model()
    end
    prop_id = ctx.triggered[1].prop_id
    if prop_id == "reset_decision_button.n_clicks"
        decision_model = make_decision_model()
    elseif prop_id == "add_device_model_button.n_clicks"
        # TODO: what if user passes the same device type twice? overwrite?
        add_device_model!(decision_model, device_type, device_formulation)
    elseif prop_id == "remove_device_model_button.n_clicks"
        remove_device_model!(decision_model, device_type, device_formulation)
    elseif prop_id == "add_optimizer_button.n_clicks"
        try
            decision_model["optimizer"] =
                from_json(Dict, PSI.Api.create_optimizer(optimizer, optimizer_settings))
        catch e
            return (loading_system, "Error: optimizer settings failed to parse: $e", [], "")
        end
    else
        error("What was pressed: $(ctx.triggered)")
    end

    decision_model["name"] = name
    decision_model["decision_problem_type"] = decision_problem_type
    decision_model["system_path"] = system_path
    decision_model["template"]["network"] = Dict("network_type" => network_type)
    unassigned_text = make_unassigned_type_md(
        "device",
        decision_model,
        [x["value"] for x in device_type_options],
    )
    return (
        unassigned_text,
        insert_json_text_in_markdown(to_json(decision_model, indent=2)),
    )
end

callback!(
    app,
    Output("saved_decision_model_text", "value"),
    Output("saved_decision_models", "data"),
    Output("decision_models_checklist", "options"),
    Input("save_decision_model_button", "n_clicks"),
    Input("saved_decision_models", "data"),
    State("dm_name_text", "value"),
    State("decision_model_text", "children"),
) do n_clicks, saved_decision_models, dm_name, decision_model_text
    n_clicks < 1 && throw(PreventUpdate())
    if isnothing(saved_decision_models)
        saved_decision_models = Dict()
    else
        try
            saved_decision_models = from_json(Dict, saved_decision_models)
        catch e
            @show saved_decision_models
            rethrow()
        end
    end
    dm_name == "" && return "Error: name must be set", to_json(saved_decision_models)
    json_text = get_json_text_from_markdown(decision_model_text)
    opt = get(from_json(Dict, json_text), "optimizer", nothing)
    if isnothing(opt)
        return "Error: an optimizer must be saved", no_update(), no_update()
    end
    model = Dict()
    try
        model = from_json(Dict, PSI.Api.create_decision_model(json_text))
    catch e
        return "Failed to create decision model: $e", no_update(), no_update()
    end

    saved_decision_models[model["name"]] = model
    dm_names = sort!([x for x in keys(saved_decision_models)])
    return join(dm_names, ", "),
    to_json(saved_decision_models),
    make_widget_options(dm_names)
end

callback!(
    app,
    Output("simulation_text", "children"),
    Input("create_sim_button", "n_clicks"),
    Input("sim_name_text", "value"),
    Input("num_steps_text", "value"),
    Input("saved_decision_models", "data"),
    State("ic_chron_radio", "value"),
    State("decision_models_checklist", "value"),
) do n_clicks, name, num_steps, saved_decision_models, ic_chron, decision_models
    n_clicks < 1 && throw(PreventUpdate())
    name == "" && return "Error: name must be set"
    if isnothing(saved_decision_models)
        saved_decision_models = Dict()
    else
        saved_decision_models = from_json(Dict, saved_decision_models)
    end
    sim = Dict(
        "name" => name,
        "models" => Dict(
            "decision_models" => [saved_decision_models[x] for x in decision_models],
        ),
        "sequence" => Dict(
            "initial_condition_chronology_type" => ic_chron,
            "feedforwards_by_model" => [],
        ),
        "num_steps" => parse(Int, num_steps),
    )

    try
        sim_json = PSI.Api.create_simulation(to_json(sim))
        return insert_json_text_in_markdown(to_json(from_json(Dict, sim_json), indent=2))
    catch e
        return "Failed to create simulation: $e"
    end
end

if !isnothing(get(ENV, "SIIP_DEBUG", nothing))
    run_server(app, "0.0.0.0", debug=true, dev_tools_hot_reload=true)
else
    run_server(app, "0.0.0.0")
end
