---@class vehicleService: Service
---@field loadingVehicles table<number, VehicleGroup> -- table of vehicles that are being loaded
---@field loadedVehicles table<number, VehicleGroup> -- table of vehicles that are loaded
modules.services.vehicle = modules.services:createService("vehicle", "Handles vehicle spawning, loading, and despawning.", {"ChickenMst"})

function modules.services.vehicle:initService()
    self.loadingVehicles = {}
    self.loadedVehicles = {}

    self.onVehicleSpawn = modules.libraries.event:create()
    self.onVehicleLoad = modules.libraries.event:create()
    self.onVehicleDespawn = modules.libraries.event:create()
    self.onGroupLoad = modules.libraries.event:create()
    self.onGroupDespawn = modules.libraries.event:create()
end

function modules.services.vehicle:startService()
    if modules.addonReason ~= "create" then
        self:_load() -- load the service on creation
    end

    modules.libraries.callbacks:connect("onVehicleSpawn", function(vehicle_id, peer_id, x, y, z, group_cost, group_id)
        group_id = tostring(group_id)
        local vGroup = self.loadingVehicles[group_id]

        if not vGroup then
            vGroup = modules.classes.vehicleGroup:create(group_id, modules.services.player:getPlayerByPeer(peer_id))
        end

        if not vGroup.vehicles[vehicle_id] then
            local vehicle = modules.classes.vehicle:create(vehicle_id, group_id)
            vGroup:addVehicle(vehicle)
        end

        if modules.libraries.logging.loggingDetail == "full" then
            modules.libraries.logging:debug("onVehicleSpawn", "Vehicle spawned with id: " .. vehicle_id .. ", group id: " .. group_id)
        end
        self.loadingVehicles[group_id] = vGroup
        self.onVehicleSpawn:fire(vGroup, vehicle_id)
        self:_save()
    end)

    modules.libraries.callbacks:connect("onVehicleLoad", function(vehicle_id)
        local vGroup = self:getVehicleGroup(vehicle_id)
        if not vGroup then
            modules.libraries.logging:info("onVehicleLoad", "Vehicle group not found for vehicle id: " .. vehicle_id)
            return
        end
        vGroup.vehicles[vehicle_id]:loaded()
        self.onVehicleLoad:fire(vGroup, vehicle_id)

        local loaded = true
        for _, vehicle in pairs(vGroup.vehicles) do
            if not vehicle.isLoaded then
                loaded = false
            end
        end

        if loaded and not vGroup.isLoaded then
            modules.libraries.logging:debug("onVehicleLoad", "Vehicle group loaded with id: " .. vGroup.groupId)
            vGroup:loaded()
            self.loadedVehicles[tostring(vGroup.groupId)] = vGroup
            self.loadingVehicles[tostring(vGroup.groupId)] = nil
            self.onGroupLoad:fire(vGroup)
            self:_save()
        end
    end)

    modules.libraries.callbacks:connect("onVehicleDespawn", function(vehicle_id, peer_id)
        local vGroup = self:getVehicleGroup(vehicle_id)
        if not vGroup then
            modules.libraries.logging:info("onVehicleDespawn()", "Vehicle group not found for vehicle id: " .. vehicle_id)
            return
        end

        if vGroup.vehicles[vehicle_id] then
            if modules.libraries.logging.loggingDetail == "full" then
                modules.libraries.logging:debug("onVehicleDespawn", "Vehicle despawned with id: " .. vehicle_id .. ", group id: " .. vGroup.groupId)
            end
            vGroup.vehicles[vehicle_id]:despawned()
            self.onVehicleDespawn:fire(vGroup, vehicle_id)
        end

        local despawned = true
        for _, vehicle in pairs(vGroup.vehicles) do
            if not vehicle.isDespawned then
                despawned = false
            end
        end

        if despawned then
            modules.libraries.logging:debug("onVehicleDespawn", "Vehicle group despawned with id: " .. vGroup.groupId)
            vGroup:despawned()
            self.onGroupDespawn:fire(vGroup)
            self.loadedVehicles[vGroup.groupId] = nil
            self:_save()
        end
    end)
end

--- get a vehicle group by its vehicle id
---@param vehicle_id number
---@param mustBeLoaded boolean|nil
function modules.services.vehicle:getVehicleGroup(vehicle_id, mustBeLoaded)
    local g
    for _, vGroup in pairs(self.loadedVehicles) do
        if vGroup.vehicles[vehicle_id] then
            g = vGroup
        end
    end
    if not g and not mustBeLoaded then
        for _, vGroup in pairs(self.loadingVehicles) do
            if vGroup.vehicles[vehicle_id] then
                g = vGroup
            end
        end
    end
    return g
end

-- get all vehicle groups owned by a player
---@param player Player
---@return table<number, VehicleGroup>
function modules.services.vehicle:getPlayersVehicleGroups(player)
    local groups = {}
    for _, vGroup in pairs(self.loadedVehicles) do
        if modules.services.player:isSamePlayer(vGroup.owner,player) then
            table.insert(groups, vGroup)
        end
    end
    for _, vGroup in pairs(self.loadingVehicles) do
        if modules.services.player:isSamePlayer(vGroup.owner,player) then
            table.insert(groups, vGroup)
        end
    end
    return groups
end

-- internal function to save the vehicles service
function modules.services.vehicle:_save()
    modules.libraries.gsave:saveService("vehicle", self)
end

-- internal function to load the saved vehicles from gsave
function modules.services.vehicle:_load()
    local service = modules.libraries.gsave:loadService("vehicle")

    if not service then
        modules.libraries.logging:warning("vehicle:_load", "Skiped loading vehicles service, no data found.")
        return
    end

    if service.loadingVehicles then
        local rebuilt = {} -- table to rebuild loading vehicles
        for _,vGroup in pairs(service.loadingVehicles) do
            local rebuiltGroup = modules.classes.vehicleGroup:create(vGroup.groupId, modules.services.player:getPlayer(vGroup.owner.steamId), vGroup.spawnTime)
            for _, vehicle in pairs(vGroup.vehicles) do
                local rebuiltVehicle = modules.classes.vehicle:create(vehicle.id, vGroup.groupId, vehicle.isLoaded)
                rebuiltGroup:addVehicle(rebuiltVehicle)
            end
            rebuilt[rebuiltGroup.groupId] = rebuiltGroup
        end
        self.loadingVehicles = rebuilt
    end

    if service.loadedVehicles then
        local rebuilt = {} -- table to rebuild loading vehicles
        for _,vGroup in pairs(service.loadedVehicles) do
            local rebuiltGroup = modules.classes.vehicleGroup:create(vGroup.groupId, modules.services.player:getPlayer(vGroup.owner.steamId), vGroup.spawnTime, vGroup.isLoaded)
            for _, vehicle in pairs(vGroup.vehicles) do
                local rebuiltVehicle = modules.classes.vehicle:create(vehicle.id, vGroup.groupId, vehicle.isLoaded, vehicle.data, vehicle.info)
                rebuiltGroup:addVehicle(rebuiltVehicle)
            end
            rebuilt[rebuiltGroup.groupId] = rebuiltGroup
        end
        self.loadedVehicles = rebuilt
    end
end