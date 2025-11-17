modules.classes.vehicle = {} -- table of vehicle functions

---@param vehicleId number
---@param groupId number|string
---@param loaded boolean|nil
---@return Vehicle
function modules.classes.vehicle:create(vehicleId, groupId, loaded, data, info)
    ---@class Vehicle
    local vehicle = {
        _class = "Vehicle",
        id = vehicleId,
        groupId = tostring(groupId),
        data = data or nil,
        info = info or nil,
        onDespawn = modules.libraries.event:create(),
        onLoaded = modules.libraries.event:create(),
        isLoaded = loaded or false,
        isDespawned = false
    }

    -- sets the vehicles isDespawned state to true and fires the onDespawn event
    function vehicle:despawned()
        self.isDespawned = true
        self.onDespawn:fire(self)
    end

    -- sets the vehicles isLoaded state to true and fires the onLoaded event
    function vehicle:loaded()
        self.onLoaded:fire(self)
        self.isLoaded = true
    end

    function vehicle:setEditable(state)
        return server.setVehicleEditable(self.id, state)
    end

    function vehicle:setInvulnerable(state)
        return server.setVehicleInvulnerable(self.id, state)
    end

    function vehicle:despawn(is_instant)
        server.despawnVehicle(self.id, is_instant or false)
    end

    function vehicle:getInfo(update)
        self.info = (update and server.getVehicleComponents(self.id) or (self.info or server.getVehicleComponents(self.id)))
        return self.info
    end

    function vehicle:getData(update)
        self.data = (update and server.getVehicleData(self.id) or (self.data or server.getVehicleData(self.id)))
        return self.data
    end

    function vehicle:getComponents(update)
        return (update and self:getInfo(update) or (self.info and self.info.components or self:getInfo(update).components))
    end

    function vehicle:setTooltip(text)
        return server.setVehicleTooltip(self.id, text)
    end

    function vehicle:getPos()
        return server.getVehiclePos(self.id)
    end

    function vehicle:save()
        local group = modules.services.vehicle:getVehicleGroup(self.id)
        group:addVehicle(self)
        group:save()
    end

    return vehicle
end