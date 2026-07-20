---@class tpsService: Service
---@field targetTPS number -- target TPS (ticks per second)
---@field tps number -- current TPS (ticks per second)
---@field _last number -- last tick time in milliseconds
modules.services.tps = modules.services:createService("tps", "Service for calculating and managing tps", {"ChickenMst"})

function modules.services.tps:initService()
    self.targetTPS = modules.libraries.settings:getValue("targetTPS",true,0) -- target TPS (ticks per second)
    self.tpsHistoryLength = modules.libraries.settings:getValue("tpsHistoryLength",true,10) -- length of the TPS history
    self.tps = 0 -- current TPS (ticks per second)
    self.averageTPS = 0 -- average TPS (ticks per second)
    self.tpsHistory = {} -- history of TPS values
    self._last = server.getTimeMillisec() -- last tick time in milliseconds
end

function modules.services.tps:startService()
    modules.libraries.callbacks:connect("onTick", function (game_ticks)
        local now = server.getTimeMillisec()

        if self.targetTPS ~= 0 then
            while self:_calculateTPS(self._last, now, game_ticks) > self.targetTPS do
                now = server.getTimeMillisec() -- update the current time
            end
        end

        self.tps = self:_calculateTPS(self._last, now, game_ticks)
        table.insert(self.tpsHistory, self.tps)
        if #self.tpsHistory > self.tpsHistoryLength then
            table.remove(self.tpsHistory, 1)
        end
        self.averageTPS = self:_calculateAverageTPS()
        self._last = server.getTimeMillisec() -- update the last tick time
    end)
end

-- internal function to calculate the TPS (ticks per second)
---@param last number last tick time in milliseconds
---@param now number current tick time in milliseconds
---@param ticks number number of ticks since the last tick
---@return number TPS (ticks per second)
function modules.services.tps:_calculateTPS(last, now, ticks)
    return 1000 / (now - last) * ticks
end

-- internal function to calculate the average TPS (ticks per second)
---@return number average TPS (ticks per second)
function modules.services.tps:_calculateAverageTPS()
    local sum = 0
    for _, tps in pairs(self.tpsHistory) do
        sum = sum + tps
    end
    return math.min(sum / #self.tpsHistory, 62)
end

-- get the current TPS (ticks per second)
---@return number TPS (ticks per second)
function modules.services.tps:getTPS()
    return self.tps
end

-- get the average TPS (ticks per second)
---@return number average TPS (ticks per second)
function modules.services.tps:getAverageTPS()
    return self:_calculateAverageTPS()
end

-- set the target for the TPS limiting
---@param targetTPS number
function modules.services.tps:setTPS(targetTPS)
    if targetTPS < 0 then
        targetTPS = 0 -- disable TPS limiting if targetTPS is negative
    end

    self.targetTPS = targetTPS -- set the target TPS
end