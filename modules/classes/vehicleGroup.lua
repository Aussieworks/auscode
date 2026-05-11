modules.classes.vehicleGroup = {} -- table of vehicle functions

---@param group_id number|string
---@param owner Player|nil
---@param spawnTime number|nil
---@param loaded boolean|nil
---@return VehicleGroup
function modules.classes.vehicleGroup:create(group_id, owner, spawnTime, loaded, despawned)
    ---@class VehicleGroup
    local vehicleGroup = {
        _class = "VehicleGroup",
        groupId = tostring(group_id),
        vehicles = {}, ---@type Vehicle[]
        ownerId = owner and owner.steamId,
        spawnTime = spawnTime or server.getTimeMillisec(),
        onDespawn = modules.libraries.event:create(),
        onLoaded = modules.libraries.event:create(),
        isLoaded = loaded or false,
        isDespawned = despawned or false,
    }

    -- fires the onDespawn event
    function vehicleGroup:despawned()
        self.isDespawned = true
        self.onDespawn:fire(self)
    end

    -- sets the vehicle group as loaded and fires the onLoaded event
    function vehicleGroup:loaded()
        self.isLoaded = true
        self.onLoaded:fire(self)
    end

    -- sets the vehicle groups owner
    ---@param newowner Player
    function vehicleGroup:setOwner(newowner)
        self.ownerId = newowner.steamId
    end

    ---@return Player|nil
    function vehicleGroup:getOwner()
        return modules.services.player:getPlayer(self.ownerId)
    end

    -- adds a vehicle to the vehicle group
    ---@param vehicle Vehicle
    function vehicleGroup:addVehicle(vehicle)
        self.vehicles[vehicle.id] = vehicle
    end

    -- sets the vehicle groups editability
    ---@param state boolean
    function vehicleGroup:setEditable(state)
        for _, vehicle in pairs(self.vehicles) do
            if not vehicle.isDespawned then
                vehicle:setEditable(state)
            end
        end
    end

    -- sets the vehicle groups invulnerability
    ---@param state boolean
    function vehicleGroup:setInvulnerable(state)
        for _, vehicle in pairs(self.vehicles) do
            if not vehicle.isDespawned then
                vehicle:setInvulnerable(state)
            end
        end
    end

    -- despawns the vehicle group
    ---@param is_instant boolean|nil if true the vehicle group will be despawned instantly, if false it will be despawned when unloaded
    function vehicleGroup:despawn(is_instant)
        server.despawnVehicleGroup(self.groupId, is_instant or false)
    end

    -- gets the vehicle groups info, this is a combined info of all vehicles in the group
    ---@param update boolean|nil if true the vehicle info will be fetched from the server, otherwise the cached info will be returned
    ---@return table info
    function vehicleGroup:getInfo(update)
        local info = {}
        info["characters"] = info["characters"] or {}
        info["components"] = info["components"] or {}
        for _, vehicle in pairs(self.vehicles) do
            local vinfo = vehicle:getInfo(update)
            info["mass"] = (info["mass"] or 0) + (vinfo.mass or 0)
            info["voxels"] = (info["voxels"] or 0) + (vinfo.voxels or 0)
            for _, id in pairs(vinfo.characters) do
                table.insert(info["characters"], id)
            end
            for i, v in pairs(vinfo.components) do
                if #v > 0 then
                    info["components"][i] = info["components"][i] or {}
                    for _, comp in pairs(v) do
                        table.insert(info["components"][i], comp)
                    end
                else
                    info["components"][i] = v
                end
            end
        end
        return info
    end

    -- sets the vehicle groups tooltip text
    ---@param text string
    function vehicleGroup:setTooltip(text)
        for _, vehicle in pairs(self.vehicles) do
            if not vehicle.isDespawned then
                vehicle:setTooltip(text)
            end
        end
    end

    -- sets the vehicle groups position
    ---@param pos table matrix
    function vehicleGroup:setPos(pos)
        server.setGroupPos(self.groupId, pos)
    end

    -- sets the vehicle groups position, will be displaced by other vehicles
    ---@param pos table matrix
    function vehicleGroup:setPosSafe(pos)
        server.setGroupPosSafe(self.groupId, pos)
    end

    -- resets the vehicle groups state, all vehicles in the group will be reset to the state they were in when they were spawned
    function vehicleGroup:resetState()
        for _, vehicle in pairs(self.vehicles) do
            if not vehicle.isDespawned then
                vehicle:resetState()
            end
        end
    end

    function vehicleGroup:save()
        modules.services.vehicle:_updateVehicle(self)
    end

    return vehicleGroup
end