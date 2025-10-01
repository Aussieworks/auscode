auscode.vehicle = {} -- vehicle related functions

modules.services.vehicle.onGroupload:connect(function(group)
    group:setEditable(not group.owner:getExtra("as"))
    group:setInvulnerable(not group.owner:getExtra("pvp"))
end)