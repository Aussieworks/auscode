modules.classes.tracker = {}

---@param id number
---@param target Player|Vehicle
---@param updateFrequency number
---@param useTime boolean
---@return Tracker
function modules.classes.tracker:create(id, target, updateFrequency, useTime)
    ---@class Tracker
    local tracker = {
        _class = "Tracker",
        id = id,
        target = target,
        updateFrequency = updateFrequency or 1,
        useTime = useTime or false,
        pos = self.target:getPos()
    }

    function tracker:_updatePos()
        self.pos = self.target:getPos()
    end

    function tracker:update()
        self:_updatePos()
        modules.services.tracker:_updateTracker(self)
    end

    function tracker:getPos()
        return self.pos
    end

    return tracker
end