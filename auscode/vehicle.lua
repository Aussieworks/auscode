---@class ACVehicle : ACModule
auscode.vehicle = auscode.classes.module:create("vehicle", {"ChickenMst"}, "vehicle handleing for auscode") -- vehicle related functions

function auscode.vehicle:_init(safeMode)
    return true
end

function auscode.vehicle:_start(safeMode)
    self.onGroupLoadConnection = modules.services.vehicle.onGroupLoad:connect(function(group)
        group:setEditable(not group:getOwner():getExtra("as"))
        group:setInvulnerable(not group:getOwner():getExtra("pvp"))

        local firstVehicle = {}
        for _, vehicle in pairs(group.vehicles) do
            firstVehicle = vehicle
            break
        end

        group:setTooltip("Owner: "..group:getOwner().name.."\nGroup ID: "..group.groupId)
        modules.services.ui:createMapLabel("Owner: "..group:getOwner().name.."\nGroup ID: "..group.groupId, 0)
        modules.services.ui:createMapObject("Vehicle", "Owner: "..group:getOwner().name.."\nGroup ID: "..group.groupId, modules.classes.widgets.color:create(0,255,0), 1, 1, 0, 0, firstVehicle.id)
    end)
    return true
end

function auscode.vehicle:_cleanup()
    self.onGroupLoadConnection:disconnect()
end