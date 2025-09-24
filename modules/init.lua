-- init modules table
modules = {}

require "modules.classes" -- load the classes
require "modules.libraries" -- load the libraries

modules.isDedicated = false -- is the server dedicated?

modules.addonReason = "unknown" -- can be "create", "reload", or "load". or unknown if not set

modules.onStart = modules.classes.event:create() -- event for when the server starts

modules.onServiceInit = modules.classes.event:create() -- event for when a service is initialized

-- add services after loading everything else
require "modules.services" -- load the services

-- internal function to set the isDedicated variable
function modules:_setIsDedicated()
    local host = server.getPlayers()[1]
    self.isDedicated = host and (host.steam_id == 0 and host.object_id == nil)
    modules.libraries.logging:info("modules.isDedicated", tostring(modules.isDedicated))
end

-- connect into onCreate for setup of modules
modules.libraries.callbacks:once("onCreate", function(is_world_create)
    local function setup(startTime, is_world_create)
        modules.libraries.callbacks:once("onTick", function()
            local took = server.getTimeMillisec() - startTime
            modules.addonReason = is_world_create and "create" or (took < 1000 and "reload" or "load")
            modules:_setIsDedicated() -- set the isDedicated variable
            modules.libraries.logging:info("modules.addonReason", modules.addonReason)

            if not g_savedata then
                modules.libraries.logging:warning("modules.onCreate", "g_savedata is not initialized, initializing.")
                -- setup gsave
                g_savedata = {
                    modules = {
                        services = {}
                    }
                }
            end

            modules.services:_initServices() -- initialize all services
            modules.onServiceInit:fire() -- fire the onServiceInit event

            modules.services:_startServices() -- start all services

            local startUpTook = server.getTimeMillisec() - startTime
            modules.libraries.logging:debug("onStart", "Took: "..tostring(startUpTook).."ms to start modules")

            modules.libraries.logging:debug("onStart", "modules started. fireing onStart event")
            modules.onStart:fire()
        end)
    end

    setup(server.getTimeMillisec(), is_world_create)
end)

-- SSSWTool tracing support, since modules messes with callbacks via `_ENV` at runtime.
if SSSW_DBG then
    if SSSW_DBG.level == "full" then
        SSSW_DBG.expected_stack_onTick = {"_ENV[name]", "`existing(...)`"}
    else
        SSSW_DBG.expected_stack_onTick = {"_ENV[name]"}
    end
    SSSW_DBG.expected_stack_httpReply = SSSW_DBG.expected_stack_onTick
	modules.libraries.callbacks:_initCallback("onTick")
	modules.libraries.callbacks:_initCallback("httpReply")
end