---@class ACVehicle : ACModule
auscode.vehicle = auscode.classes.module:create("vehicle", {"ChickenMst"}, "vehicle handleing for auscode") -- vehicle related functions

function auscode.vehicle:_init(safeMode)
    self.mapObjects = modules.libraries.settings:getValue("auscodeVehicleMapObjects", true, true)
    self.allowWorkshop = modules.libraries.settings:getValue("auscodeVehicleAllowWorkshop", true, true)
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

        for _, vehicle in pairs(group.vehicles) do
            vehicle:setTooltip(string.format("Owner: %s\nGroup ID: %s Vehicle ID: %s",group:getOwner().name,group.groupId, vehicle.id))
            if self.mapObjects then
                modules.services.ui:createMapObject("Vehicle", string.format("Owner: %s\nGroup ID: %s Vehicle ID: %s",group:getOwner().name,group.groupId, vehicle.id), modules.classes.widgets.color:create(0,255,0), 1, 12, 0, 0, vehicle.id, nil, nil, "vehicleGroup"..group.groupId)
            end
        end
    end)

    self.onGroupDespawnConnection = modules.services.vehicle.onGroupDespawn:connect(function(group)
        local widgets = modules.services.ui:getWidgetsByName("vehicleGroup"..group.groupId)

        for _, widget in pairs(widgets) do
            modules.services.ui:removeWidget(widget.id)
        end
    end)
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