---@class loopService: Service
---@field loops table<number, Loop> -- table of loops
modules.services.loop = modules.services:createService("loop", "Service for creating and managing loops", {"ChickenMst"})

function modules.services.loop:initService()
    self.loops = {} -- table of loops
end

function modules.services.loop:startService()
    modules.libraries.callbacks:connect("onTick", function ()
        local timeNow = server.getTimeMillisec()
        for _, v in pairs(self.loops) do
            if timeNow >= v.creationTime + (v.time * 1000) and not v.paused then
                v.callback()
                v.creationTime = timeNow
            end
        end
    end)
end

-- create a new loop
---@param time number
---@param func function
function modules.services.loop:create(time, func)
    local loop = modules.classes.loop:create(time, func, #self.loops)

    self.loops[loop.id] = loop
end

-- delete a loop
---@param id number
function modules.services.loop:remove(id)
    if self.loops[id] then
        self.loops[id] = nil
    end
end