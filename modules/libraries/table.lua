modules.libraries.table = {}

-- https://github.com/cuhHub/Noir/blob/v2.0.0/src/Noir/Built-Ins/Libraries/Table.lua
-- Converts a table to a string representation with indentation.
---@param tbl table The table to convert.
---@param indent number|nil The current indentation level (default is 0).
---@return string -- The string representation of the table.
function modules.libraries.table:tostring(tbl, indent)
    -- Set default indent
    if not indent then
        indent = 0
    end

    -- Create a table for later
    local toConcatenate = {}

    -- Convert the table to a string
    for index, value in pairs(tbl) do
        -- Get value type
        local valueType = type(value)

        -- Format the index for later
        local formattedIndex = ("[%s]:"):format(type(index) == "string" and "\""..index.."\"" or tostring(index):gsub("\n", "\\n"))

        -- Format the value
        local toAdd = formattedIndex

        if valueType == "table" then
            -- Format table
            local nextIndent = indent + 2
            local formattedValue = self:tostring(value, nextIndent)

            -- Check if empty table
            if formattedValue == "" then
                formattedValue = "{}"
            else
                formattedValue = "\n"..formattedValue
            end

            -- Add to string
            toAdd = toAdd..(" %s"):format(formattedValue)
        elseif valueType == "number" or valueType == "boolean" then
            toAdd = toAdd..(" %s"):format(tostring(value))
        else
            toAdd = toAdd..(" \"%s\""):format(tostring(value):gsub("\n", "\\n"))
        end

        -- Add to table
        table.insert(toConcatenate, ("  "):rep(indent)..toAdd)
    end

    -- Return the table as a formatted string
    return table.concat(toConcatenate, "\n")
end

---@param tbl table The table to strip.
---@param typeOf string The type to strip from the table.
---@return table -- The stripped table.
function modules.libraries.table:strip(tbl, typeOf)
    local stripped = {}
    for k, v in pairs(tbl) do
        if type(v)=="table" then
            if v._class and v._class == "EventConnection" or v._class == "Event" then
                goto continue
            end
        end

        if type(v) == typeOf then
            goto continue
        end

        if type(v) == "table" then
            stripped[k] = self:strip(v, typeOf)
        else
            stripped[k] = v
        end

        ::continue::
    end
    return stripped
end

---@param tbl any table to copy
---@return table -- a deep copy of the table
function modules.libraries.table:deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end