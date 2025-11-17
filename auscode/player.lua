---@class ACPlayer: ACModule
auscode.player = auscode.classes.module:create("player", {"ChickenMst"}, "player handleing for auscode") -- player related functions

function auscode.player:_init(safeMode)
    return true
end

function auscode.player:_start(safeMode)
    self.onJoinConnection = modules.services.player.onJoin:connect(function(player)
        modules.libraries.chat:announce("AusCode", string.format("Welcome %s!, %s %s",player.name,player:getExtra("as"),player:getExtra("pvp")))
        auscode.player:toggleAntisteal(player, player:getExtra("as") or false)
        auscode.player:togglePVP(player, player:getExtra("pvp") or false)
    end)

    self.onLoadConnection = modules.services.player.onLoad:connect(function(player)
        local widgets = modules.services.ui:getPlayersWidgets(player)

        for _, widget in pairs(widgets) do
            if widget.type == "popupScreen" and widget.name == "playerUi" then
                modules.services.ui:removeWidget(widget.id)
            end
        end

        local widget = modules.services.ui:createPopupScreen("Loading", -0.9, 0.85 , true, player, "playerUi")
        widget:_remove(player)
        widget:update()
    end)

    self.onLeaveConnection = modules.services.player.onLeave:connect(function(player)
        local widgets = modules.services.ui:getPlayersWidgets(player)
        for _, widget in pairs(widgets) do
            if widget.type == "popupScreen" and widget.name == "playerUi" then
                modules.services.ui:removeWidget(widget.id)
            end
        end
    end)
end

function auscode.player:_cleanup()
    self.onJoinConnection:disconnect()
end

function auscode.player:toggleAntisteal(player, state)
    if state == nil then
        state = not player:getExtra("as")
    end

    player:setExtra("as", state)
    player:save()

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
    if state == nil then
        state = not player:getExtra("pvp")
    end

    player:setExtra("pvp", state)
    player:save()

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
    if state == nil then
        state = not player:getExtra("ui")
    end

    player:setExtra("ui", state)
    player:save()

    local widgets = modules.services.ui:getPlayersShownWidgets(player)
    for _, widget in pairs(widgets) do
        if widget.type == "popupScreen" then
            widget.visible = player:getExtra("ui")
            widget:update()
            widget:save()
        end
    end
end