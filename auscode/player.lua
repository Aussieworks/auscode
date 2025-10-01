auscode.player = {} -- player related functions

---@param player Player
modules.services.player.onJoin:connect(function(player)
    auscode.player:toggleAntisteal(player:getExtra("as") or false)
    modules.libraries.logging:debug("Player", tostring(player:getExtra("as")))

    modules.libraries.chat:announce("AusCode", "Welcome " .. player.name .. "!")
end)

function auscode.player:toggleAntisteal(player, state)
    player:setExtra("as", state or not player:getExtra("as"))

    local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
    if #vehicles > 0 then
        for _, group in pairs(vehicles) do
            group:setEditable(not player:getExtra("as"))
            modules.libraries.logging:debug("AusCode","Set vehicle group: "..group.groupId.." editable to: "..tostring(not player:getExtra("as")))
        end
    else
        modules.libraries.logging:debug("AusCode","No vehicle groups found for player "..player.name)
    end
end

function auscode.player:togglePVP(player, state)
    player:setExtra("pvp", state or not player:getExtra("pvp"))

    
end