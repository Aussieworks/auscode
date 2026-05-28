---@class ACVehicle : ACModule
auscode.vehicle = auscode.classes.module:create("vehicle", {"ChickenMst"}, "vehicle handleing for auscode") -- vehicle related functions

function auscode.vehicle:_init(safeMode)
    self.mapObjects = modules.libraries.settings:getValue("auscodeVehicleMapObjects", true, true)
    self.allowWorkshop = modules.libraries.settings:getValue("auscodeVehicleAllowWorkshop", true, true)
    self.voxelLimit = modules.libraries.settings:getValue("auscodeVehicleVoxelLimit", true, 10000)
    self.subBodyLimit = modules.libraries.settings:getValue("auscodeVehicleSubBodyLimit", true, 10)
    self.groupLimit = modules.libraries.settings:getValue("auscodeVehicleGroupLimit", true, 1)
    self.timeLimit = modules.libraries.settings:getValue("auscodeVehicleTimeLimit", true, 0)
    return true
end

function auscode.vehicle:_start(safeMode)
    server.setGameSetting("map_show_vehicles", not self.mapObjects)

    self.onVehicleSpawnConnection = modules.services.vehicle.onVehicleSpawn:connect(function(vehicleGroup, vehicleId)
        if not self.allowWorkshop and self:isWorkshop(vehicleGroup, vehicleGroup:getOwner()) then
            local player = vehicleGroup:getOwner()
            player:notify("Vehicle", "Workshop vehicles are not allowed. Vehicle despawned.", 6)
            vehicleGroup:despawn(true)
            return
        end
    end)

    self.onGroupLoadConnection = modules.services.vehicle.onGroupLoad:connect(function(group)
        group:setEditable(not group:getOwner():getExtra("as"))
        group:setInvulnerable(not group:getOwner():getExtra("pvp"))

        if self:getVoxelCount(group) > self.voxelLimit then
            local player = group:getOwner()
            player:notify("Vehicle", "Your vehicle/s voxel count exceeds the limit ("..self:getVoxelCount(group).."/"..self.voxelLimit.."). Vehicle despawned.", 6)
            group:despawn(true)
            return
        end

        if self:getSubBodyCount(group) > self.subBodyLimit then
            local player = group:getOwner()
            player:notify("Vehicle", "Your vehicle/s sub-body count exceeds the limit ("..self:getSubBodyCount(group).."/"..self.subBodyLimit.."). Vehicle despawned.", 6)
            group:despawn(true)
            return
        end

        if self.timeLimit > 0 and group:getLoadingTime() > self.timeLimit then
            local player = group:getOwner()
            player:notify("Vehicle", "Your vehicle/s spawn time has exceeded the limit ("..group:getLoadingTime().."/"..self.timeLimit.."ms). Vehicle despawned.", 6)
            group:despawn(true)
            return
        end

        while count(modules.services.vehicle:getPlayersVehicleGroups(group:getOwner(), true)) > self.groupLimit do
            local oldestGroup = self:getOldestGroup(modules.services.vehicle:getPlayersVehicleGroups(group:getOwner(), true))
            if oldestGroup then
                local player = group:getOwner()
                player:notify("Vehicle", "You have exceeded the maximum number of vehicle groups ("..self.groupLimit.."). Oldest vehicle group despawned.", 1)
                oldestGroup:despawn(true)
            else
                break
            end
        end

        for _, vehicle in pairs(group.vehicles) do
            vehicle:setTooltip(string.format("Owner: %s\nGroup ID: %s Vehicle ID: %s",group:getOwner().name,group.groupId, vehicle.id))
            if self.mapObjects then
                modules.services.ui:createMapObject("Vehicle", string.format("Owner: %s\nGroup ID: %s Vehicle ID: %s",group:getOwner().name,group.groupId, vehicle.id), modules.classes.widgets.color:create(0,255,0), 1, 12, 0, 0, vehicle.id, nil, nil, "vehicleGroup"..group.groupId)
            end
        end

        modules.libraries.chat:announce("[Vehicle] Spawn", string.format("%s Spawned vehicle group: %s (Voxels: %s, Sub-Bodies: %s Time: %sms)",group:getOwner().name,group.groupId,self:getVoxelCount(group),self:getSubBodyCount(group),group:getLoadingTime()), -1)
    end)

    self.onGroupDespawnConnection = modules.services.vehicle.onGroupDespawn:connect(function(group)
        local widgets = modules.services.ui:getWidgetsByName("vehicleGroup"..group.groupId)

        for _, widget in pairs(widgets) do
            modules.services.ui:removeWidget(widget.id)
        end
    end)

    self.vehicleUITask = modules.services.task:create(1, function(task)
        if not self.mapObjects then
            task:setPaused(true)
            task:update()
            return
        end

        for _, player in pairs(modules.services.player:getOnlinePlayers()) do
            for _, group in pairs(modules.services.vehicle:getPlayersVehicleGroups(player, true)) do
                local vehicleUi = {}
                for _, widget in pairs(modules.services.ui:getWidgetsByName("vehicleGroup"..group.groupId)) do
                    vehicleUi[widget.parentId] = widget
                end
                for _, vehicle in pairs(group.vehicles) do
                    local pos = vehicle:getPos()
                    local x,y,z = matrix.position(pos)
                    local widget = vehicleUi[vehicle.id]

                    if widget then
                        widget.markerType = y <= 5 and 17 or y <= 200 and 12 or 13
                        widget.x = x
                        widget.z = z
                        widget:update()
                    end
                end
            end
        end
    end, true, false)

    return true
end

function auscode.vehicle:_cleanup()
    self.onGroupLoadConnection:disconnect()
    self.onGroupDespawnConnection:disconnect()
    self.onVehicleSpawnConnection:disconnect()
end

function auscode.vehicle:isWorkshop(vehicleGroup, player)
    for _, vehicle in pairs(vehicleGroup.vehicles) do
        local data = vehicle:getData()
        if data and data.authors then
            for _, author in pairs(data.authors) do
                if author.steamId == player.steamId then
                    return false
                end
            end
        end
        if count(data.authors) == 0 then
            return false
        end
    end

    return true
end

---@param group VehicleGroup|nil
---@return number
function auscode.vehicle:getVoxelCount(group)
    if not group then return 0 end
    local info = group:getInfo()
    if info and info.voxels then
        return info.voxels
    end
    return 0
end

---@param group VehicleGroup|nil
function auscode.vehicle:getSubBodyCount(group)
    if not group then return 0 end

    return count(group.vehicles)
end

---@param groups VehicleGroup[]
function auscode.vehicle:getOldestGroup(groups)
    local oldest = 0
    local oldestGroup = nil
    for i, group in pairs(groups) do
        if group and group.spawnTime then
            if not oldestGroup or group.spawnTime < oldest then
                oldest = group.spawnTime
                oldestGroup = group
            end
        end
    end
    return oldestGroup
end