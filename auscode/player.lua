---@class ACPlayer: ACModule
auscode.player = auscode.classes.module:create("player", {"ChickenMst"}, "player handleing for auscode") -- player related functions

function auscode.player:_init(safeMode)
    return true
end

function auscode.player:_start(safeMode)
    self.onJoinConnection = modules.services.player.onJoin:connect(function(player)
        auscode.player:toggleAntisteal(player, player:getExtra("as") or false)
        auscode.player:togglePVP(player, player:getExtra("pvp") or false)

        modules.libraries.chat:announce("AusCode", "Welcome " .. player.name .. "!")
    end)
end

function auscode.player:_cleanup()
    self.onJoinConnection:disconnect()
end

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

---@param player Player
function auscode.player:toggleUI(player, state)
    player:setExtra("ui", state or not player:getExtra("ui"))

    local widgets = modules.services.ui:getPlayersShownWidgets(player)
    for _, widget in pairs(widgets) do
        if widget.type == "popupScreen" then
            widget.visible = player:getExtra("ui")
            widget:update()
        end
    end
end