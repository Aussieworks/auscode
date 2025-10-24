modules.libraries.settings = {}
-- this doesnt have any logging because the logging lib requires the settings lib meaning that its either logging cant use settings or settings cant use logging

modules.libraries.settings._settings = require "settings"

-- create a new setting with the inputed name, value and default
---@param name string
---@param value any
---@param default any
---@return any
function modules.libraries.settings:create(name,value,default)
    if not self._settings[name] then
        self._settings[name] = {value = value, default = default}
        return self._settings[name]
    end
end

-- get the setting with the inputed name, if it does not exist return the default value
---@param name string
---@param default any
---@return any
function modules.libraries.settings:getSetting(name,default)
    if not self._settings[name] or self._settings.value then
        return default
    end
    return self._settings[name].value
end

-- get the value of the setting with the inputed name, if it does not exist create it if createSettingIfNotExists is true
---@param name string
---@param createSettingIfNotExists boolean
---@param default any
---@return any
function modules.libraries.settings:getValue(name,createSettingIfNotExists,default)
    if not self._settings[name] then
        if createSettingIfNotExists then
            self:create(name, default, default)
            return default
        end
        return default
    end
    if self._settings[name].value == nil then
        if not self._settings[name].default then
            self._settings[name].default = default
        end
        return self._settings[name].default
    end
    return self._settings[name].value
end

-- set the value of the setting with the inputed name, if it does not exist do nothing
---@param name string
---@param value any
function modules.libraries.settings:setValue(name,value)
    if not self._settings[name] then
        return
    end
    self._settings[name].value = value
end

-- set the default value of the setting with the inputed name, if it does not exist do nothing
---@param name string
---@param default any
function modules.libraries.settings:setDefault(name,default)
    if not self._settings[name] then
        return
    end
    self._settings[name].default = default
end

-- get the default value of the setting with the inputed name, if it does not exist returns nil
---@param name string
function modules.libraries.settings:getDefault(name)
    if not self._settings[name] then
        return
    end
    return self._settings[name].default
end

-- reset the value of the setting with the inputed name to its default value, if it does not exist do nothing
---@param name string
function modules.libraries.settings:resetToDefault(name)
    if not self._settings[name] then
        return
    end
    if not self._settings[name].default then
        return
    end
    self._settings[name].value = self._settings[name].default
end