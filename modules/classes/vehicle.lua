modules.classes.vehicle = {} -- table of vehicle functions

---@param vehicleId number
---@param groupId number|string
---@param loaded boolean|nil
---@return Vehicle
function modules.classes.vehicle:create(vehicleId, groupId, loaded)
    ---@class Vehicle
    local vehicle = {
        _class = "Vehicle",
        id = vehicleId,
        groupId = tostring(groupId),
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

    return vehicle
end