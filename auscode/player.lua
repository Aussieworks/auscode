---@class ACPlayer: ACModule
auscode.player = auscode.classes.module:create("player", {"ChickenMst"}, "player handleing for auscode") -- player related functions

function auscode.player:_init(safeMode)
    self.playerPermissions = modules.libraries.settings:getValue("auscodePlayerPermissions", true, {})

    self.playerDefaultPermissions = modules.libraries.settings:getValue("auscodePlayerDefaultPermissions", true, {})

    self.playerDefaultStates = modules.libraries.settings:getValue("auscodePlayerDefaultStates", true, {as=true,pvp=false,ui=true})

    self.playerItemLookup = modules.libraries.settings:getValue("auscodePlayerItemLookup", true, {})

    self.playerDefaultItems = modules.libraries.settings:getValue("auscodePlayerDefaultItems", true, {})

    self.playerDespawnDroppedItems = modules.libraries.settings:getValue("auscodePlayerDespawnDroppedItems", true, true)

    self.playerDroppedItemDespawnTime = modules.libraries.settings:getValue("auscodePlayerDroppedItemDespawnTime", true, 20)

    self.playerPermissionsWeight = modules.libraries.settings:getValue("auscodePlayerPermissionsWeight", true, {})

    self.playerPermissionsTag = modules.libraries.settings:getValue("auscodePlayerPermissionsTag", true, {})

    return true
end

function auscode.player:_start(safeMode)
    for _, player in pairs(modules.services.player:getOnlinePlayers()) do
        self:updatePerms(player)
        self:giveDefaultPerms(player)
        self:toggleAntisteal(player, player:getExtra("as") or false)
        self:togglePVP(player, player:getExtra("pvp") or false)
    end

    self.onJoinConnection = modules.services.player.onJoin:connect(function(player)
        self:updatePerms(player)
        self:giveDefaultPerms(player)
        self:toggleAntisteal(player, self.playerDefaultStates.as)
        self:togglePVP(player, self.playerDefaultStates.pvp)
        self:toggleUI(player, self.playerDefaultStates.ui)
        modules.libraries.chat:announce("AusCode", string.format("Welcome %s!, %s %s",player.name,(player:getExtra("as")~=nil and player:getExtra("as") or player:getExtra("as")==nil and "nil"),(player:getExtra("pvp")~=nil and player:getExtra("pvp") or player:getExtra("pvp")==nil and "nil")))
        self:giveDefaultItems(player)
    end)

    self.onLoadConnection = modules.services.player.onLoad:connect(function(player)
        local widgets = modules.services.ui:getPlayersWidgets(player)

        for _, widget in pairs(widgets) do
            if widget.type == "popupScreen" and widget.name == "playerUi" then
                modules.services.ui:removeWidget(widget.id)
            end
        end

        local widget = modules.services.ui:createPopupScreen("Loading", -0.9, 0.8, true, player, "playerUi")
        widget:_remove(player)
        widget:update()

        self:toggleUI(player, self.playerDefaultStates.ui)
    end)

    self.onLeaveConnection = modules.services.player.onLeave:connect(function(player)
        local widgets = modules.services.ui:getPlayersWidgets(player)
        for _, widget in pairs(widgets) do
            if widget.type == "popupScreen" and widget.name == "playerUi" then
                modules.services.ui:removeWidget(widget.id)
            end
        end

        local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
        for _, group in pairs(vehicles) do
            if not group.isDespawned then
                group:despawn(true)
            end
        end
    end)

    self.onItemDropConnection = modules.services.player.onItemDrop:connect(function(player, itemObjectId, item)
        if self.playerDespawnDroppedItems then
            local task = modules.services.task:create(self.playerDroppedItemDespawnTime, function()
                server.despawnObject(itemObjectId, true)
            end, false, true)
        end
    end)

    self.onRespawnConnection = modules.services.player.onRespawn:connect(function(player)
        self:giveDefaultItems(player)
    end)

    self.pvpEffectsTask = modules.services.task:create(1, function()
        for _, player in pairs(modules.services.player:getOnlinePlayers()) do
            if player:getExtra("pvp") == false then
                local playerData = player:getData(true)
                if playerData.dead or playerData.incapacitated then
                    player:revive()
                end

                if playerData.hp and playerData.hp < 100 and not (playerData.dead or playerData.incapacitated) then
                    if playerData.hp ~= 0 then
                        player:setHp(100)
                    else
                        player:revive()
                    end
                end
            end
        end
    end, true, false)

    -- player ui task
    self.playerUITask = modules.services.task:create(10, function(task)
        local players = modules.services.player:getOnlinePlayers()
        for _, player in pairs(players) do
            local widgets = modules.services.ui:getPlayersWidgets(player)
            for _, widget in pairs(widgets) do
                if widget.type == "popupScreen" and widget.name == "playerUi" then
                    widget.text = string.format("[Server]\n[TPS]: %.0f\n[UpTime]: \n%s\n[Player]\n[AS]: %s\n[PVP]: %s", modules.services.tps:getTPS(), auscode.utility:formatTime(modules.services.tps._last), (player:getExtra("as") and "True" or "False"), (player:getExtra("pvp") and "True" or "False"))
                    widget:update()
                end
            end
        end
    end, true, false)

    return true
end

function auscode.player:_cleanup()
    self.onJoinConnection:disconnect()
    self.onLoadConnection:disconnect()
    self.onLeaveConnection:disconnect()
    self.onItemDropConnection:disconnect()
    self.onRespawnConnection:disconnect()
end

---@param player Player
---@param state boolean|nil
function auscode.player:toggleAntisteal(player, state)
    if state == nil then
        state = not player:getExtra("as")
    end

    player:setExtra("as", state)
    player:save()

    local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
    if count(vehicles) > 0 then
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

---@param player Player
---@param state boolean|nil
function auscode.player:togglePVP(player, state)
    if state == nil then
        state = not player:getExtra("pvp")
    end

    player:setExtra("pvp", state)
    player:save()

    local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
    if count(vehicles) > 0 then
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
---@param state boolean|nil
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

---@param player Player
function auscode.player:giveItem(player, item, bool, int, float, slot)
    if not item then return false end

    if type(item) == "string" then
        local foundItem = self.playerItemLookup[item]
        if not foundItem then
            modules.libraries.logging:info("AusCode", "Item with name: %s not found in playerItemLookup, cannot give item to player: %s", item, player.name)
            return false
        end
        item = foundItem
    end

    local inventory = {}
    for i=1, 10 do
        inventory[i]=player:getItem(i) or 0
    end

    if not slot then
        for i=1, 10 do
            if inventory[i] == 0 then
                if player:setItem(i, item, bool, int, float) then
                    modules.libraries.logging:info("AusCode", "Given item: %s to player: %s in slot: %s", item, player.name, i)
                    return true
                end
            end
        end
        return false
    end

    return player:setItem(slot, item, bool, int, float)
end

function auscode.player:giveDefaultItems(player)
    for slot, itemData in pairs(self.playerDefaultItems) do
        self:giveItem(player, itemData[1], itemData[2], itemData[3], itemData[4], slot)
    end
end

function auscode.player:clearPerms(player)
    for perm, _ in pairs(player:getPerms()) do
        player:removePerm(perm)
    end
    player:save()
end

---@param player Player
function auscode.player:giveDefaultPerms(player)
    for _, perm in pairs(self.playerDefaultPermissions) do
        player:setPerm(perm, true)
    end
end

---@param player Player
function auscode.player:updatePerms(player)
    modules.libraries.logging:info("AusCode","Updating permissions for player: %s", player.name)
    local permissions = {}
    if self.playerPermissions and self.playerPermissions[player.steamId] then
        permissions = self.playerPermissions[player.steamId]
    else
        return
    end

    self:clearPerms(player)

    for _, perm in pairs(permissions) do
        player:setPerm(perm, true)
    end
    player:save()
end

function auscode.player:getPermTag(perm)
    return self.playerPermissionsTag[perm] or ""
end

-- get the highest permission level for a player
function auscode.player:getHighestPerm(player)
    local perms = player:getPerms()
    local topPerm = nil
    local topWeight = 0

    for perm, _ in pairs(perms) do
        local weight = self.playerPermissionsWeight[perm] or 0
        if weight > topWeight then
            topPerm = perm
            topWeight = weight
        end
    end

    return topPerm
end