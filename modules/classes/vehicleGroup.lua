modules.classes.vehicleGroup = {} -- table of vehicle functions

---@param group_id number|string
---@param owner Player|nil
---@param spawnTime number|nil
---@param loaded boolean|nil
---@return VehicleGroup
function modules.classes.vehicleGroup:create(group_id, owner, spawnTime, loaded)
    ---@class VehicleGroup
    local vehicleGroup = {
        _class = "VehicleGroup",
        groupId = tostring(group_id),
        vehicles = {}, ---@type Vehicle[]
        owner = owner,
        spawnTime = spawnTime or server.getTimeMillisec(),
        onDespawn = modules.libraries.event:create(),
        onLoaded = modules.libraries.event:create(),
        isLoaded = loaded or false,
    }

    -- fires the onDespawn event
    function vehicleGroup:despawned()
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
        self.owner = newowner
    end

    -- adds a vehicle to the vehicle group
    ---@param vehicle Vehicle
    function vehicleGroup:addVehicle(vehicle)
        if not self.vehicles[vehicle.id] then
            self.vehicles[vehicle.id] = vehicle
        end
    end

    function vehicleGroup:setEditable(state)
        for _, vehicle in pairs(self.vehicles) do
            if not vehicle.isDespawned then
                vehicle:setEditable(state)
            end
        end
    end

    function vehicleGroup:setInvulnerable(state)
        for _, vehicle in pairs(self.vehicles) do
            if not vehicle.isDespawned then
                vehicle:setInvulnerable(state)
            end
        end
    end

    function vehicleGroup:despawn(is_instant)
        server.despawnVehicleGroup(self.groupId, is_instant or false)
    end

<<<<<<< HEAD
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

=======
>>>>>>> b44d1ee7267fd09cc2d27808470fc4a67a41ffc8
    return vehicleGroup
end