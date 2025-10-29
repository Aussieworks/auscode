---@class addonService: Service
---@field addons table<string, Addon>
modules.services.addon = modules.services:createService("addons", "Addons Service", {"ChickenMst"})

function modules.services.addon:initService()
    self.addons = {} ---@type table <string, Addon>
    require "addons" -- load the addons
end

function modules.services.addon:startService()
    self:_loadAddons() -- load the addons
end

-- create a new addon with the inputed name, version, description and authors
---@param name string
---@param version string|number
---@param description string
---@param authors table<string>
---@return Addon
function modules.services.addon:createAddon(name, version, description, authors)
    if self.addons[name] then
        modules.libraries.logging:error("services.addon:connect()", "Addon '%s' already exists", name) -- print an error to the console
    end

    local addon = modules.classes.addon:create(name, version, description, authors) -- create a new addon instance

    self.addons[name] = addon

    return addon -- return the addon instance
end

-- remove the addon with the inputed name from the addons table, if it exists
---@param name string name of the addon to remove
function modules.services.addon:disconnect(name)
    if self.addons[name] then
        self.addons[name]:disable()
        self.addons[name] = nil -- remove the addon from the addons table
        modules.libraries.logging:debug("services.addon:disconnect()", "Addon '%s' disconnected", name) -- print a debug message to the console
    else
        modules.libraries.logging:error("services.addon:disconnect()", "Addon '%s' does not exist", name) -- print an error to the console
    end
end

-- enable the addon with the inputed name, if it exists and is not already enabled
---@param name string
function modules.services.addon:enable(name)
    if self.addons[name] then
        if self.addons[name].enabled then
            modules.libraries.logging:debug("services.addon:enable()", "Addon '%s' is already enabled", name) -- print a debug message to the console
            return
        end
        self.addons[name]:enable() -- enable the addon
        self.addons[name]:_init() -- run the init function of the addon
        self.addons[name]:_start() -- run the start function of the addon
        modules.libraries.logging:debug("services.addon:enable()", "Addon '%s' enabled", name) -- print a debug message to the console
        return
    else
        modules.libraries.logging:error("services.addon:enable()", "Addon '%s' does not exist", name) -- print an error to the console
    end
end

-- disable the addon with the inputed name, if it exists and is not already disabled
---@param name string
function modules.services.addon:disable(name)
    if self.addons[name] then
        if not self.addons[name].enabled then
            modules.libraries.logging:debug("services.addon:disable()", "Addon '%s' is already disabled", name) -- print a debug message to the console
            return
        end
        self.addons[name]:disable() -- disable the addon
        modules.libraries.logging:debug("services.addon:disable()", "Addon '%s' disabled", name) -- print a debug message to the console
        return
    else
        modules.libraries.logging:error("services.addon:disable()", "Addon '%s' does not exist", name) -- print an error to the console
    end
end

-- internal function to load all addons in the addons table
function modules.services.addon:_loadAddons()
    for name, addon in pairs(self.addons) do
        modules.libraries.logging:debug("services.addon", "Loading addon: '%s'", name)
        if not addon.hasInit then
            modules.libraries.logging:debug("services.addon", "Initializing addon: '%s'", name)
            if addon:_init() then
                modules.libraries.logging:debug("services.addon", "Addon '%s' initialized", name)
            else
                modules.libraries.logging:warning("services.addon", "Addon '%s' failed to initialize, disableing addon", name)
                self:disable(name) -- disable the addon if it fails to load
            end
        else
            modules.libraries.logging:debug("services.addon", "Skipped Initializing Addon '%s'. already initialized", name)
        end

        if not addon.hasStarted and addon.hasInit then
            if addon:_start() then
                modules.libraries.logging:debug("services.addon", "Addon '%s' started", name)
            else
                modules.libraries.logging:error("services.addon", "Addon '%s' failed to start", name)
                self:disable(name) -- disable the addon if it fails to start
            end
        else
            modules.libraries.logging:debug("services.addon", "Skipped starting Addon '%s'. already started", name)
        end
    end
end