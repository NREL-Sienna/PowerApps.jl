# TODO: This code will likely be moved to PowerSystems once the team has customized it for
# all types.

using DataStructures

function make_component_table(
    ::Type{T},
    sys::System;
    sort_column = "name",
) where {T<:PowerSystems.Component}
    return _make_component_table(get_components(T, sys); sort_column = sort_column)
end

function make_component_table(
    filter_func::Function,
    ::Type{T},
    sys::System;
    sort_column = "name",
) where {T<:PowerSystems.Component}
    return _make_component_table(
        get_components(filter_func, T, sys);
        sort_column = sort_column,
    )
end

function _make_component_table(components; sort_column = "name")
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
    vals = DataStructures.OrderedDict{String,Any}("name" => get_name(component))
    t = typeof(component)
    for (name, type) in zip(fieldnames(t), fieldtypes(t))
        if type <: AbstractString || type <: Number || type <: Bool
            vals[string(name)] = getproperty(component, name)
        end
    end

    vals["has_time_series"] = has_time_series(component)
    return vals
end

function get_component_table_values(component::Bus)
    return DataStructures.OrderedDict{String,Any}(
        "name" => get_name(component),
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
        "name" => get_name(component),
        "available" => get_available(component),
        "prime_mover" => string(get_prime_mover(component)),
        "fuel" => string(get_fuel(component)),
        "bus" => get_name(get_bus(component)),
        "base_power" => get_base_power(component),
        "rating" => get_rating(component),
        "active_power" => get_active_power(component),
        "reactive_power" => get_reactive_power(component),
        "has_time_series" => has_time_series(component),
    )
    return data
end
