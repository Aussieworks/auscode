modules.libraries.json = {}

---@param obj any
---@return "nil"|"boolean"|"number"|"string"|"table"|"function"|"array"
function modules.libraries.json:kindOf(obj)
    if type(obj) ~= "table" then
        return type(obj) ---@diagnostic disable-line
    end

    local i = 1

    for _ in pairs(obj) do
        if obj[i] ~= nil then
            i = i + 1
        else
            return "table"
        end
    end

    if i == 1 then
        return "table"
    else
        return "array"
    end
end

--[[
    Escapes a string for JSON.<br>
    Used internally. Do not use in your code.
]]
---@param str string
---@return string
function modules.libraries.json:escapeString(str)
    -- Escape the string
    local inChar  = { "\\", "\"", "\b", "\f", "\n", "\r", "\t" }
    local outChar = { "\\", "\"", "b", "f", "n", "r", "t" }

    for i, c in ipairs(inChar) do
        str = str:gsub(c, "\\" .. outChar[i])
    end

    return str
end

---@param str string
---@param pos integer
---@param delim string
---@param errIfMissing boolean|nil
---@return integer
---@return boolean
function modules.libraries.json:skipDelim(str, pos, delim, errIfMissing)
    -- Main logic
    pos = pos + #str:match("^%s*", pos)

    if str:sub(pos, pos) ~= delim then
        if errIfMissing then
            return 0, false
        end

        return pos, false
    end

    return pos + 1, true
end

---@param str string
---@param pos integer
---@param val string|nil
---@return string
---@return integer
function modules.libraries.json:parseStringValue(str, pos, val)
    -- Parsing
    val = val or ""

    -- local earlyEndError = "End of input found while parsing string."

    if pos > #str then
        return "", 0
    end

    local c = str:sub(pos, pos)

    if c == "\"" then
        return val, pos + 1
    end

    if c ~= "\\" then return
        self:parseStringValue(str, pos + 1, val .. c)
    end

    local escMap = {b = "\b", f = "\f", n = "\n", r = "\r", t = "\t"}
    local nextc = str:sub(pos + 1, pos + 1)

    if not nextc then
        return "", 0
    end

    return self:parseStringValue(str, pos + 2, val..(escMap[nextc] or nextc))
end

---@param str string
---@param pos integer
---@return integer
---@return integer
function modules.libraries.json:parseNumberValue(str, pos)
    -- Parse number
    local numStr = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
    local val = tonumber(numStr)

    if not val then
        return 0, 0
    end

    return val, pos + #numStr
end

---@param obj table|number|string|boolean|nil
---@param asKey boolean|nil
---@return string
function modules.libraries.json:encode(obj, asKey)
    -- Encode the object into a JSON string
    local s = {}
    local kind = self:kindOf(obj)

    if kind == "array" then
        if asKey then
            return ""
        end

        s[#s + 1] = "["

        for i, val in ipairs(obj --[[@as table]]) do
            if i > 1 then
                s[#s + 1] = ","
            end

            s[#s + 1] = self:encode(val)
        end

        s[#s + 1] = "]"
    elseif kind == "table" then
        if asKey then
            return ""
        end

        s[#s + 1] = "{"

        for k, v in pairs(obj --[[@as table]]) do
            if #s > 1 then
                s[#s + 1] = ","
            end

            s[#s + 1] = self:encode(k, true)
            s[#s + 1] = ":"
            s[#s + 1] = self:encode(v)
        end

        s[#s + 1] = "}"
    elseif kind == "string" then
        return "\""..self:escapeString(obj --[[@as string]]).."\""
    elseif kind == "number" then
        if asKey then
            return "\"" .. tostring(obj) .. "\""
        end

        return tostring(obj)
    elseif kind == "boolean" then
        return tostring(obj)
    elseif kind == "nil" then
        return "null"
    else
        return ""
    end

    return table.concat(s)
end

modules.libraries.json._Null = {}

---@param str string
---@param pos integer|nil
---@param endDelim string|nil
---@return any
---@return integer
function modules.libraries.json:decode(str, pos, endDelim)
    -- Decode a JSON string into a Lua object
    pos = pos or 1

    if pos > #str then
        return nil, 0
    end

    pos = pos + #str:match("^%s*", pos)
    local first = str:sub(pos, pos)

    if first == "{" then
        local obj, key, delimFound = {}, true, true
        pos = pos + 1

        while true do
            key, pos = self:decode(str, pos, "}")

            if key == nil then
                return obj, pos
            end

            if not delimFound then
                return nil, 0
            end

            pos = self:skipDelim(str, pos, ":", true)

            obj[key], pos = self:decode(str, pos)
            pos, delimFound = self:skipDelim(str, pos, ",")
        end
    elseif first == "[" then
        local arr, val, delimFound = {}, true, true
        pos = pos + 1

        while true do
            val, pos = self:decode(str, pos, "]")

            if val == nil then
                return arr, pos
            end

            if not delimFound then
                return nil, 0
            end

            arr[#arr + 1] = val
            pos, delimFound = self:skipDelim(str, pos, ",")
        end
    elseif first == "\"" then
        return self:parseStringValue(str, pos + 1)
    elseif first == "-" or first:match("%d") then
        return self:parseNumberValue(str, pos)
    elseif first == endDelim then
        return nil, pos + 1
    else
        local literals = {
            ["true"] = true,
            ["false"] = false,
            ["null"] = self._Null
        }

        for litStr, litVal in pairs(literals) do
            local litEnd = pos + #litStr - 1

            if str:sub(pos, litEnd) == litStr then
                if litVal == self._Null then
                    return nil, litEnd + 1
                end

                return litVal, litEnd + 1
            end
        end

        return nil, 0
    end
end