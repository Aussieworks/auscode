modules.classes.tracker = {}

---@param id number
---@param target Player|Vehicle
---@param updateFrequency number
---@param useTime boolean
---@return Tracker
function modules.classes.tracker:create(id, target, targetId, updateFrequency, useTime)
    ---@class Tracker
    local tracker = {
        _class = "Tracker",
        id = id,
        target = target,
        targetId = targetId,
        targetType = target and target._class or "none",
        updateFrequency = updateFrequency or 1,
        useTime = useTime or false,
        pos = matrix.translation(0,0,0),
    }

    function tracker:_updatePos()
        if not self.target then
            self.target = self:getTarget()
        else
            self.pos = self.target:getPos()
        end
    end

    function tracker:getTarget()
        if self.targetType == "Player" then
            return modules.services.player:getPlayer(self.targetId)
        elseif self.targetType == "Vehicle" then
            return modules.services.vehicle:getVehicleGroup(self.targetId).vehicles[self.targetId]
        end
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