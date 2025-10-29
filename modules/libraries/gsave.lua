modules.libraries.gsave = {}

-- save the inputed service into g_savedata
---@param name string name of the service
---@param service any the service to save
function modules.libraries.gsave:saveService(name, service)
    local localservice = self:_strip(service)
    self:_checkGsave(name)

    g_savedata.modules.services[name] = localservice
end

-- load the service from g_savedata
---@param name string name of the service
---@return Service|table -- the service loaded from g_savedata, or an empty table if not found
function modules.libraries.gsave:loadService(name)
    self:_checkGsave(name)

    if not g_savedata.modules.services[name] then
        modules.libraries.logging:debug("gsave:loadService", "Service '%s' not found in g_savedata, returning empty table.", name)
        self:_fixGsave(name)
        return {}
    end

    return g_savedata.modules.services[name]
end

-- internal function to check if g_savedata is initialized and has the necessary structure
---@param name string name of the service to check
function modules.libraries.gsave:_checkGsave(name)
    if not g_savedata then
        self:_fixGsave(name)
    end

    if not g_savedata.modules then
        self:_fixGsave(name)
    end

    if not g_savedata.modules.services then
        self:_fixGsave(name)
    end
end

-- internal function to ensure g_savedata has the correct structure
---@param name string|nil name of the service to ensure exists in g_savedata
function modules.libraries.gsave:_fixGsave(name)
    if not g_savedata then
        g_savedata = {}
    end

    if not g_savedata.modules then
        g_savedata.modules = {}
    end

    if not g_savedata.modules.services then
        g_savedata.modules.services = {}
    end

    if name and not g_savedata.modules.services[name] then
        g_savedata.modules.services[name] = {}
    end
end

-- internal function to purge the g_savedata and reset it to a default state
function modules.libraries.gsave:_purgeGsave()
    g_savedata = nil
    self:_fixGsave()
    modules.libraries.logging:info("gsave:_purgeGsave", "GSave data purged and reset.")
end

-- internal function to strip functions from a table
---@param tbl table the table to strip
---@return table -- a new table with functions removed
function modules.libraries.gsave:_strip(tbl)
    return modules.libraries.table:strip(tbl, "function")
end