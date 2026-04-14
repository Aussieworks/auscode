---@class ACVehicle : ACModule
auscode.vehicle = auscode.classes.module:create("vehicle", {"ChickenMst"}, "vehicle handleing for auscode") -- vehicle related functions

function auscode.vehicle:_init(safeMode)
    return true
end

function auscode.vehicle:_start(safeMode)
    self.onGroupLoadConnection = modules.services.vehicle.onGroupLoad:connect(function(group)
        group:setEditable(not group:getOwner():getExtra("as"))
        group:setInvulnerable(not group:getOwner():getExtra("pvp"))

        for _, vehicle in pairs(group.vehicles) do
            vehicle:setTooltip(string.format("Owner: %s\nGroup ID: %s Vehicle ID: %s",group:getOwner().name,group.groupId, vehicle.id))
            modules.services.ui:createMapObject("Vehicle", string.format("Owner: %s\nGroup ID: %s Vehicle ID: %s",group:getOwner().name,group.groupId, vehicle.id), modules.classes.widgets.color:create(0,255,0), 1, 12, 0, 0, vehicle.id, nil, nil, "vehicleGroup"..group.groupId)
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
end