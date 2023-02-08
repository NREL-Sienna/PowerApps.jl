# TODO: This code will likely be moved to PowerSystems once the team has customized it for
# all types.

using DataStructures

function make_component_table(
    ::Type{T},
    sys::System;
    sort_column = "Name",
) where {T<:PowerSystems.Component}
    return _make_component_table(get_components(T, sys); sort_column = sort_column)
end

function make_component_table(
    filter_func::Function,
    ::Type{T},
    sys::System;
    sort_column = "Name",
) where {T<:PowerSystems.Component}
    return _make_component_table(
        get_components(filter_func, T, sys);
        sort_column = sort_column,
    )
end

function _make_component_table(components; sort_column = "Name")
    table = Vector{DataStructures.OrderedDict{String,Any}}()
    for component in components
        push!(table, get_component_table_values(component))
    end

    isempty(table) && return table
    if !isnothing(sort_column)
        if !in(sort_column, keys(table[1]))
            throw(ArgumentError("$sort_column is not a column in the table"))
        end
        sort!(table, by = x -> x[sort_column])
    end

    return table
end

function get_component_table_values(component::PowerSystems.Component)
    vals = DataStructures.OrderedDict{String,Any}("Name" => get_name(component))
    t = typeof(component)

    if hasfield(t, :bus)
        vals["Bus"] = get_name(get_bus(component))
        vals["Area"] = get_name(get_area(get_bus(component)))
    end

    vals["has_time_series"] = has_time_series(component)
    return vals
end

function get_reactive_power_min_limit(component)
    if isnothing(get_reactive_power_limits(component))
        return 0.0
    else
        return get_reactive_power_limits(component).min
    end
end

function get_reactive_power_max_limit(component)
    if isnothing(get_reactive_power_limits(component))
        return 0.0
    else
        return get_reactive_power_limits(component).max
    end
end

function get_ramp_up_limit(component)
    if isnothing(get_ramp_limits(component))
        return 0.0
    else
        return get_ramp_limits(component).up
    end
end
function get_ramp_down_limit(component)
    if isnothing(get_ramp_limits(component))
        return 0.0
    else
        return get_ramp_limits(component).down
    end
end

function get_up_time_limit(component)
    if isnothing(get_time_limits(component))
        return 0.0
    else
        return get_time_limits(component).up
    end
end

function get_down_time_limit(component)
    if isnothing(get_time_limits(component))
        return 0.0
    else
        return get_time_limits(component).down
    end
end

function get_component_table_values(component::Bus)
    return DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "number" => get_number(component),
        "bustype" => string(get_bustype(component)),
        "angle" => get_angle(component),
        "magnitude" => get_magnitude(component),
        "base_voltage" => get_base_voltage(component),
        "area" => get_name(get_area(component)),
        "load_zone" => get_name(get_load_zone(component)),
    )
end

function get_component_table_values(component::ThermalStandard)
    data = DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "Prime Mover" => string(get_prime_mover(component)),
        "Fuel" => string(get_fuel(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base_power" => get_base_power(component),
        "rating" => get_rating(component),
        "active_power" => get_active_power(component),
        "reactive_power" => get_reactive_power(component),
        "Max Active Power_limits" => get_active_power_limits(component).min,
        "Min Active Power_limits" => get_active_power_limits(component).max,
        "Max Reactive Power_limits" => get_reactive_power_min_limit(component),
        "Min Reactive Power_limits" => get_reactive_power_max_limit(component),
        "Ramp Rate Up" => get_ramp_up_limit(component),
        "Ramp Rate Down" => get_ramp_down_limit(component),
        "Minimum Up Time" => get_up_time_limit(component),
        "Minimun Down Time" => get_down_time_limit(component),
        "Status" => get_status(component),
        "Time at Status" => get_time_at_status(component),
        "has_time_series" => has_time_series(component),
        # TODO: cost data
    )
    return data
end

function get_component_table_values(component::RenewableDispatch)
    data = DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "Prime Mover" => string(get_prime_mover(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base_power" => get_base_power(component),
        "rating" => get_rating(component),
        "active_power" => get_active_power(component),
        "reactive_power" => get_reactive_power(component),
        "Max Reactive Power_limits" => get_reactive_power_min_limit(component),
        "Min Reactive Power_limits" => get_reactive_power_max_limit(component),
        "has_time_series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::HydroDispatch)
    data = DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "Prime Mover" => string(get_prime_mover(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base_power" => get_base_power(component),
        "rating" => get_rating(component),
        "active_power" => get_active_power(component),
        "reactive_power" => get_reactive_power(component),
        "Max Active Power_limits" => get_active_power_limits(component).min,
        "Min Active Power_limits" => get_active_power_limits(component).max,
        "Max Reactive Power_limits" => get_reactive_power_min_limit(component),
        "Min Reactive Power_limits" => get_reactive_power_max_limit(component),
        "Ramp Rate Up" => get_ramp_up_limit(component),
        "Ramp Rate Down" => get_ramp_down_limit(component),
        "Minimum Up Time" => get_up_time_limit(component),
        "Minimun Down Time" => get_down_time_limit(component),
        "has_time_series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::HydroEnergyReservoir)
    data = DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "Prime Mover" => string(get_prime_mover(component)),
        "Bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base_power" => get_base_power(component),
        "rating" => get_rating(component),
        "active_power" => get_active_power(component),
        "reactive_power" => get_reactive_power(component),
        "Max Active Power_limits" => get_active_power_limits(component).min,
        "Min Active Power_limits" => get_active_power_limits(component).max,
        "Max Reactive Power_limits" => get_reactive_power_min_limit(component),
        "Min Reactive Power_limits" => get_reactive_power_max_limit(component),
        "Ramp Rate Up" => get_ramp_up_limit(component),
        "Ramp Rate Down" => get_ramp_down_limit(component),
        "Minimum Up Time" => get_up_time_limit(component),
        "Minimun Down Time" => get_down_time_limit(component),
        "Inflow" => get_inflow(component),
        "Initial Energy" => get_initial_storage(component),
        "Storage Capacity" => get_storage_capacity(component),
        "Conversion Factor" => get_conversion_factor(component),
        "Time at Status" => get_time_at_status(component),
        "has_time_series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::GenericBattery)
    data = DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "Prime Mover" => string(get_prime_mover(component)),
        "Bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base_power" => get_base_power(component),
        "rating" => get_rating(component),
        "active_power" => get_active_power(component),
        "reactive_power" => get_reactive_power(component),
        "Max Input Active Power_limits" => get_input_active_power_limits(component).min,
        "Min Input Active Power_limits" => get_input_active_power_limits(component).max,
        "Max Output Active Power_limits" =>
            get_output_active_power_limits(component).min,
        "Min Output Active Power_limits" =>
            get_output_active_power_limits(component).max,
        "Max Reactive Power_limits" => get_reactive_power_min_limit(component),
        "Min Reactive Power_limits" => get_reactive_power_max_limit(component),
        "Efficiency In" => get_efficiency(component).in,
        "Efficiency Out" => get_efficiency(component).out,
        "has_time_series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::ACBranch)
    return DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "active_power_flow" => get_active_power_flow(component),
        "reactive_power_flow" => get_reactive_power_flow(component),
        "From Bus" => get_name(get_from(get_arc(component))),
        "To Bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "b" => get_b(component),
        "rate" => get_rate(component),
        "angle_limits" => get_angle_limits(component),
    )
end

function get_component_table_values(component::MonitoredLine)
    return DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "active_power_flow" => get_active_power_flow(component),
        "reactive_power_flow" => get_reactive_power_flow(component),
        "From Bus" => get_name(get_from(get_arc(component))),
        "To Bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "b" => get_b(component),
        "flow_limits" => get_flow_limits(component),
        "rate" => get_rate(component),
        "angle_limits" => get_angle_limits(component),
    )
end

function get_component_table_values(component::PhaseShiftingTransformer)
    return DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "active_power_flow" => get_active_power_flow(component),
        "reactive_power_flow" => get_reactive_power_flow(component),
        "From Bus" => get_name(get_from(get_arc(component))),
        "To Bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "primary_shunt" => get_primary_shunt(component),
        "tap" => get_tap(component),
        "α" => get_α(component),
        "b" => get_b(component),
        "rate" => get_rate(component),
    )
end

function get_component_table_values(component::Union{TapTransformer,Transformer2W})
    return DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "available" => get_available(component),
        "active_power_flow" => get_active_power_flow(component),
        "reactive_power_flow" => get_reactive_power_flow(component),
        "From Bus" => get_name(get_from(get_arc(component))),
        "To Bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "primary_shunt" => get_primary_shunt(component),
        "tap" => get_tap(component),
        "b" => get_b(component),
        "rate" => get_rate(component),
    )
end

function get_component_table_values(component::Reserve)
    return DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "Available" => get_available(component),
        "Time frame" => get_time_frame(component),
        "Requirement" => get_requirement(component),
    )
end

function get_component_table_values(component::StaticLoad)
    return DataStructures.OrderedDict{String,Any}(
        "Name" => get_name(component),
        "Available" => get_available(component),
        "Bus" => get_name(get_bus(component)),
        "Area" => get_name(get_area(get_bus(component))),
        "Active_power" => get_active_power(component),
        "Reactive_power" => get_reactive_power(component),
        "Max_active_power" => get_max_active_power(component),
        "Max_reactive_power" => get_max_reactive_power(component),
    )
end
