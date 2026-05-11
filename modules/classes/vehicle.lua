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

    -- sets the vehicles editable state, if state is true the vehicle can be edited by players, if false it cannot be edited
    ---@param state boolean
    function vehicle:setEditable(state)
        return server.setVehicleEditable(self.id, state)
    end

    -- sets the vehicles invulnerable state, if state is true the vehicle cannot be damaged by players, if false it can be damaged
    ---@param state boolean
    function vehicle:setInvulnerable(state)
        return server.setVehicleInvulnerable(self.id, state)
    end

    -- despawns the vehicle
    ---@param is_instant boolean|nil if true the vehicle will be despawned instantly, if false it will be despawned when unloaded
    function vehicle:despawn(is_instant)
        server.despawnVehicle(self.id, is_instant or false)
    end

    -- get the vehicles info
    ---@param update boolean|nil if true the vehicle info will be fetched from the server, otherwise the cached info will be returned
    function vehicle:getInfo(update)
        self.info = (update and server.getVehicleComponents(self.id) or (self.info or server.getVehicleComponents(self.id)))
        return self.info
    end

    -- get the vehicles data
    ---@param update boolean|nil if true the vehicle data will be fetched from the server, otherwise the cached data will be returned
    function vehicle:getData(update)
        self.data = (update and server.getVehicleData(self.id) or (self.data or server.getVehicleData(self.id)))
        return self.data
    end

    -- get the vehicles components
    ---@param update boolean|nil if true the vehicle components will be fetched from the server, otherwise the cached components will be returned
    function vehicle:getComponents(update)
        return (update and self:getInfo(update) or (self.info and self.info.components or self:getInfo(update).components))
    end

    -- sets the vehicles tooltip text
    ---@param text string
    function vehicle:setTooltip(text)
        return server.setVehicleTooltip(self.id, text)
    end

    -- get the vehicle position
    ---@return table matrix
    ---@return boolean worked
    function vehicle:getPos()
        return server.getVehiclePos(self.id)
    end

    -- set the vehicles position
    ---@param pos table matrix
    function vehicle:setPos(pos)
        return server.setVehiclePos(self.id, pos)
    end

    -- set the vehicles position, will be displaced by other vehicles
    ---@param pos table matrix
    function vehicle:setPosSafe(pos)
        return server.setVehiclePosSafe(self.id, pos)
    end

    -- reset the vehicle state, vehicle will be reset to the state it was in when it was spawned
    function vehicle:resetState()
        server.resetVehicleState(self.id)
    end

    function vehicle:save()
        local group = modules.services.vehicle:getVehicleGroup(self.id)
        group:addVehicle(self)
        group:save()
    end

    return vehicle
end