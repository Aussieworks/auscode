---@diagnostic disable: lowercase-global
auscode = {} -- main table for auscode

require "modules" -- load modules

auscode.safeMode = modules.libraries.settings:getValue("auscodeSafeMode", false, false) -- if auscode should start in safe mode (use default settings)

auscode.restartOnError = modules.libraries.settings:getValue("auscodeRestartOnError", false, false) -- if auscode should try to recover from errors

auscode.restartCount = 0 -- number of times auscode has restarted (this does not persist across script reloads)

-- load auscode modules
require "auscode.classes"
require "auscode.player"
require "auscode.commands"
require "auscode.vehicle"

modules.onStart:connect(function()
    auscode:_start()
end)

function auscode:_start()
    for _, module in pairs(self) do
        if type(module) == "table" and module._class == "ACModule" then
            module:init(self.safeMode)
            module:start(self.safeMode)
            modules.libraries.logging:info("AusCode", "Started module: "..module.name)
        end
    end

    modules.libraries.chat:announce("AusCode", "Hello from AusCode!")
end

function auscode:_error(module, errorType, reason)
    local actions = {
        ["InvalidSettings"] = function()
            modules.libraries.logging:error("AusCode", "Invalid settings detected. Please check your AusCode configuration.")
            if self.restartOnError then
                self:restart(true)
            end
        end
    }

    modules.libraries.logging:error("AusCode", "Error: "..reason)

    if type(actions[errorType]) == "function" then
        actions[errorType]()
    end
end

---@param safeMode boolean
function auscode:restart(safeMode)
    self.restartCount = self.restartCount + 1
    for _, module in pairs(self) do
        if type(module) == "table" and module._class == "ACModule" then
            module:restart(safeMode)
            modules.libraries.logging:info("AusCode", "Restarted module: "..module.name)
        end
    end
end