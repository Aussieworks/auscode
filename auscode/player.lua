auscode.player = {} -- player related functions

---@param player Player
modules.services.player.onJoin:connect(function(player)
    auscode.player:toggleAntisteal(player, player:getExtra("as") or false)
    auscode.player:togglePVP(player, player:getExtra("pvp") or false)

    modules.libraries.chat:announce("AusCode", "Welcome " .. player.name .. "!")
end)

function auscode.player:toggleAntisteal(player, state)
    player:setExtra("as", state or not player:getExtra("as"))

    local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
    if #vehicles > 0 then
        for _, group in pairs(vehicles) do
            if not group.isDespawned then
                group:setEditable(not player:getExtra("as"))
                modules.libraries.logging:debug("AusCode","Set vehicle group: "..group.groupId.." editable to: "..tostring(not player:getExtra("as")))
            end
        end
    else
        modules.libraries.logging:debug("AusCode","No vehicle groups found for player "..player.name)
    end
end

function auscode.player:togglePVP(player, state)
    player:setExtra("pvp", state or not player:getExtra("pvp"))

    local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
    if #vehicles > 0 then
        for _, group in pairs(vehicles) do
            if not group.isDespawned then
                group:setInvulnerable(not player:getExtra("pvp"))
                modules.libraries.logging:debug("AusCode","Set vehicle group: "..group.groupId.." Invulnerable to: "..tostring(not player:getExtra("pvp")))
            end
        end
    else
        modules.libraries.logging:debug("AusCode","No vehicle groups found for player "..player.name)
    end
end