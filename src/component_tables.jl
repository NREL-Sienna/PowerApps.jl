# TODO: This code will likely be moved to PowerSystems once the team has customized it for
# all types.

using DataStructures

function make_component_table(
    ::Type{T},
    sys::System;
    sort_column = "name",
) where {T <: PowerSystems.Component}
    return _make_component_table(get_components(T, sys); sort_column = sort_column)
end

function make_component_table(
    filter_func::Function,
    ::Type{T},
    sys::System;
    sort_column = "name",
) where {T <: PowerSystems.Component}
    return _make_component_table(
        get_components(filter_func, T, sys);
        sort_column = sort_column,
    )
end

function _make_component_table(components; sort_column = "name")
    table = Vector{DataStructures.OrderedDict{String, Any}}()
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
    vals = DataStructures.OrderedDict{String, Any}("name" => get_name(component))
    t = typeof(component)

    if hasfield(t, :bus)
        vals["bus"] = get_name(get_bus(component))
        vals["area"] = get_name(get_area(get_bus(component)))
    end

    vals["has time series"] = has_time_series(component)
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
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "number" => get_number(component),
        "bustype" => string(get_bustype(component)),
        "angle" => get_angle(component),
        "magnitude" => get_magnitude(component),
        "base voltage" => get_base_voltage(component),
        "area" => get_name(get_area(component)),
        "load zone" => get_name(get_load_zone(component)),
    )
end

function get_component_table_values(component::ThermalStandard)
    data = DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "prime mover" => string(get_prime_mover(component)),
        "fuel" => string(get_fuel(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base power" => get_base_power(component),
        "rating" => get_rating(component),
        "active power" => get_active_power(component),
        "reactive power" => get_reactive_power(component),
        "max active power limits" => get_active_power_limits(component).min,
        "min active power limits" => get_active_power_limits(component).max,
        "max reactive power limits" => get_reactive_power_min_limit(component),
        "min reactive power limits" => get_reactive_power_max_limit(component),
        "ramp rate up" => get_ramp_up_limit(component),
        "ramp rate down" => get_ramp_down_limit(component),
        "min up time" => get_up_time_limit(component),
        "min down time" => get_down_time_limit(component),
        "status" => get_status(component),
        "time at status" => get_time_at_status(component),
        "has time series" => has_time_series(component),
        # TODO: cost data
    )
    return data
end

function get_component_table_values(component::RenewableDispatch)
    data = DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "prime mover" => string(get_prime_mover(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base power" => get_base_power(component),
        "rating" => get_rating(component),
        "active power" => get_active_power(component),
        "reactive power" => get_reactive_power(component),
        "max reactive power limits" => get_reactive_power_min_limit(component),
        "min reactive rower limits" => get_reactive_power_max_limit(component),
        "has time series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::HydroDispatch)
    data = DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "prime mover" => string(get_prime_mover(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base power" => get_base_power(component),
        "rating" => get_rating(component),
        "active power" => get_active_power(component),
        "reactive power" => get_reactive_power(component),
        "max active power limits" => get_active_power_limits(component).min,
        "min active power limits" => get_active_power_limits(component).max,
        "max reactive power limits" => get_reactive_power_min_limit(component),
        "min reactive power limits" => get_reactive_power_max_limit(component),
        "ramp rate up" => get_ramp_up_limit(component),
        "ramp rate down" => get_ramp_down_limit(component),
        "min up time" => get_up_time_limit(component),
        "min down time" => get_down_time_limit(component),
        "has time series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::HydroEnergyReservoir)
    data = DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "prime mover" => string(get_prime_mover(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base power" => get_base_power(component),
        "rating" => get_rating(component),
        "active power" => get_active_power(component),
        "reactive power" => get_reactive_power(component),
        "max active power limits" => get_active_power_limits(component).min,
        "min active power limits" => get_active_power_limits(component).max,
        "max reactive power limits" => get_reactive_power_min_limit(component),
        "min reactive power limits" => get_reactive_power_max_limit(component),
        "ramp rate up" => get_ramp_up_limit(component),
        "ramp rate down" => get_ramp_down_limit(component),
        "min up time" => get_up_time_limit(component),
        "min down time" => get_down_time_limit(component),
        "inflow" => get_inflow(component),
        "initial energy" => get_initial_storage(component),
        "storage capacity" => get_storage_capacity(component),
        "conversion factor" => get_conversion_factor(component),
        "time at status" => get_time_at_status(component),
        "has time series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::GenericBattery)
    data = DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "prime mover" => string(get_prime_mover(component)),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "base power" => get_base_power(component),
        "rating" => get_rating(component),
        "active_power" => get_active_power(component),
        "reactive power" => get_reactive_power(component),
        "max input active power limits" => get_input_active_power_limits(component).min,
        "min input active power limits" => get_input_active_power_limits(component).max,
        "max output active power limits" =>
            get_output_active_power_limits(component).min,
        "min output active power limits" =>
            get_output_active_power_limits(component).max,
        "max reactive power limits" => get_reactive_power_min_limit(component),
        "min reactive power limits" => get_reactive_power_max_limit(component),
        "efficiency in" => get_efficiency(component).in,
        "efficiency out" => get_efficiency(component).out,
        "has time series" => has_time_series(component),
    )
    # TODO: cost data
    return data
end

function get_component_table_values(component::ACBranch)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "active power flow" => get_active_power_flow(component),
        "reactive power flow" => get_reactive_power_flow(component),
        "from bus" => get_name(get_from(get_arc(component))),
        "to bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "from b" => get_b(component).from,
        "to b" => get_b(component).to,
        "rate" => get_rate(component),
        "angle limits min" => get_angle_limits(component).min,
        "angle limits max" => get_angle_limits(component).max,
    )
end

function get_component_table_values(component::MonitoredLine)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "active power flow" => get_active_power_flow(component),
        "reactive power flow" => get_reactive_power_flow(component),
        "from bus" => get_name(get_from(get_arc(component))),
        "to bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "from b" => get_b(component).from,
        "to b" => get_b(component).to,
        "flow limits" => get_flow_limits(component),
        "rate" => get_rate(component),
        "angle limits min" => get_angle_limits(component).min,
        "angle limits max" => get_angle_limits(component).max,
    )
end

function get_component_table_values(component::PhaseShiftingTransformer)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "active power flow" => get_active_power_flow(component),
        "reactive power flow" => get_reactive_power_flow(component),
        "from bus" => get_name(get_from(get_arc(component))),
        "to bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "primary shunt" => get_primary_shunt(component),
        "tap" => get_tap(component),
        "α" => get_α(component),
        "phase angle limits" => get_phase_angle_limits(component),
        "rate" => get_rate(component),
    )
end

function get_component_table_values(component::Transformer2W)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "active power flow" => get_active_power_flow(component),
        "reactive power flow" => get_reactive_power_flow(component),
        "from bus" => get_name(get_from(get_arc(component))),
        "to bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "primary shunt" => get_primary_shunt(component),
        "rate" => get_rate(component),
    )
end

function get_component_table_values(component::TapTransformer)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "active power flow" => get_active_power_flow(component),
        "reactive power flow" => get_reactive_power_flow(component),
        "from bus" => get_name(get_from(get_arc(component))),
        "to bus" => get_name(get_to(get_arc(component))),
        "r" => get_r(component),
        "x" => get_x(component),
        "primary shunt" => get_primary_shunt(component),
        "tap" => get_tap(component),
        "rate" => get_rate(component),
    )
end

function get_component_table_values(component::Reserve)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "time frame" => get_time_frame(component),
        "requirement" => get_requirement(component),
    )
end

function get_component_table_values(component::StaticLoad)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "active power" => get_active_power(component),
        "reactive power" => get_reactive_power(component),
        "max active power" => get_max_active_power(component),
        "max reactive power" => get_max_reactive_power(component),
    )
end

function get_component_table_values(component::StandardLoad)
    return DataStructures.OrderedDict{String, Any}(
        "name" => get_name(component),
        "available" => get_available(component),
        "bus" => get_name(get_bus(component)),
        "area" => get_name(get_area(get_bus(component))),
        "constant active power" => get_constant_active_power(component),
        "constant reactive power" => get_constant_reactive_power(component),
        "impedance active power" => get_impedance_active_power(component),
        "impedance reactive power" => get_impedance_reactive_power(component),
        "current active power" => get_current_active_power(component),
        "current reactive power" => get_current_reactive_power(component),
        "max constant active power" => get_max_constant_active_power(component),
        "max constant reactive power" => get_max_constant_reactive_power(component),
        "max impednace active power" => get_max_impedance_active_power(component),
        "max impedance reactive power" => get_max_impedance_reactive_power(component),
        "max current active power" => get_max_current_active_power(component),
        "max current reactive power" => get_max_current_reactive_power(component),
    )
end
