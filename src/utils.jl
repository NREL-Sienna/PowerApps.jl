make_widget_options(items) = [Dict("label" => x, "value" => x) for x in items]

function make_table_columns(rows)
    isempty(rows) && return []
    columns = []
    for (name, val) in first(rows)
        if val isa AbstractString
            type = "text"
        elseif val isa Number
            type = "numeric"
        else
            error("Unsupported type: $(val): $(typeof(val))")
        end
        push!(columns, Dict("name" => name, "id" => name, "type" => type))
    end

    return columns
end

function insert_json_text_in_markdown(json_text)
    return """
    ```json
    $json_text
    ```
    """
end

get_json_text_from_markdown(x) = strip(replace(replace(x, "```json" => ""), "```" => ""))
