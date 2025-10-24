---@class ACVehicle : ACModule
auscode.vehicle = auscode.classes.module:create("vehicle", {"ChickenMst"}, "vehicle handleing for auscode") -- vehicle related functions

function auscode.vehicle:_init(safeMode)
    return true
end

function auscode.vehicle:_start(safeMode)
    self.onGroupLoadConnection = modules.services.vehicle.onGroupLoad:connect(function(group)
        group:setEditable(not group.owner:getExtra("as"))
        group:setInvulnerable(not group.owner:getExtra("pvp"))

        local firstVehicle = {}
        for _, vehicle in pairs(group.vehicles) do
            firstVehicle = vehicle
            break
        end

        group:setTooltip("Owner: "..group.owner.name.."\nGroup ID: "..group.groupId)
        modules.services.ui:createMapObject("Vehicle", "Owner: "..group.owner.name.."\nGroup ID: "..group.groupId, modules.classes.widgets.color:create(0, 255, 10, 255), 1, 12, 0, 0, firstVehicle.id, group.owner, 5)
    end)
    return true
end

function auscode.vehicle:_cleanup()
    self.onGroupLoadConnection:disconnect()
end