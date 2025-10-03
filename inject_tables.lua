function parse_table_single_line(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ","
                end

                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. key .. " = {"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                if (cur_index == size) then
                    output_str = output_str .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    table.insert(output,output_str)
    output_str = table.concat(output)

    return output_str
end

function parse_table_simple(t)
    local result = "{"
    local first = true
    
    for k, v in pairs(t) do
        if not first then
            result = result .. ", "
        end
        first = false
        
        if type(k) == "number" then
            result = result .. "[" .. k .. "] = "
        else
            result = result .. "[\"" .. tostring(k) .. "\"] = "
        end
        
        if type(v) == "table" then
            result = result .. parse_table_simple(v)
        elseif type(v) == "string" then
            result = result .. "\"" .. v .. "\""
        else
            result = result .. tostring(v)
        end
    end
    
    result = result .. "}"
    return result
end

function inject_tables_into_code(code_template, tables)
    local lines = {}
    for line in code_template:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    -- Вставляем таблицы в указанные строки
    for line_index, table_data in pairs(tables) do
        if line_index <= #lines then
            lines[line_index] = lines[line_index] .. " " .. parse_table_single_line(table_data)
        end
    end
    
    return table.concat(lines, "\n")
end


return inject_tables_into_code
