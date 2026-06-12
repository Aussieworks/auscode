---@class ACPlayer: ACModule
auscode.player = auscode.classes.module:create("player", {"ChickenMst"}, "player handleing for auscode") -- player related functions

function auscode.player:_init(safeMode)
    --- settings
    self.playerAutoAuth = modules.libraries.settings:getValue("auscodePlayerAutoAuth", true, true)

    self.playerPermissions = modules.libraries.settings:getValue("auscodePlayerPermissions", true, {})

    self.playerDefaultPermissions = modules.libraries.settings:getValue("auscodePlayerDefaultPermissions", true, {})

    self.playerDefaultStates = modules.libraries.settings:getValue("auscodePlayerDefaultStates", true, {as=true,pvp=false,ui=true})

    self.playerItemLookup = modules.libraries.settings:getValue("auscodePlayerItemLookup", true, {})

    self.playerDefaultItems = modules.libraries.settings:getValue("auscodePlayerDefaultItems", true, {})

    self.playerDespawnDroppedItems = modules.libraries.settings:getValue("auscodePlayerDespawnDroppedItems", true, true)

    self.playerDroppedItemDespawnTime = modules.libraries.settings:getValue("auscodePlayerDroppedItemDespawnTime", true, 20)

    self.playerPermissionsWeight = modules.libraries.settings:getValue("auscodePlayerPermissionsWeight", true, {})

    self.playerPermissionsTag = modules.libraries.settings:getValue("auscodePlayerPermissionsTag", true, {})

    self.playerMapObjects = modules.libraries.settings:getValue("auscodePlayerMapObjects", true, true)

    self.parties = {} -- table to store player parties

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
        modules.libraries.chat:announce("[Player] Join", string.format("%s (%s) has joined the server.", player.name, player.peerId))

        local widget = modules.services.ui:createPopupScreen("Loading", -0.9, 0.77, true, player, "playerUi")
        widget:_remove(player)
        widget:update()
        self:toggleUI(player, self.playerDefaultStates.ui)

        self:giveDefaultItems(player)
    end)

    self.onLoadConnection = modules.services.player.onLoad:connect(function(player)
        player:setAuth(self.playerAutoAuth)

        local widgets = modules.services.ui:getPlayersWidgets(player)

        for _, widget in pairs(widgets) do
            if widget.type == "popupScreen" and widget.name == "playerUi" then
                modules.services.ui:removeWidget(widget.id)
            end
        end

        local widget = modules.services.ui:createPopupScreen("Loading", -0.9, 0.77, true, player, "playerUi")
        widget:_remove(player)
        widget:update()

        if self.playerMapObjects then
            local tracker = modules.services.tracker:create(player, 1, false)
            local pos = tracker:getPos()
            local x,y,z = matrix.position(pos)
            local widget = modules.services.ui:createMapObject(string.format("%s (%s)",player.name, player.peerId), nil, modules.classes.widgets.color:create(0,255,0), 0, 1, x, z, nil, nil, nil, "playerMapObject"..player.peerId)
        end

        self:toggleUI(player, self.playerDefaultStates.ui)

        auscode.chat:send()
    end)

    self.onLeaveConnection = modules.services.player.onLeave:connect(function(player)
        local widgets = modules.services.ui:getPlayersWidgets(player)
        for _, widget in pairs(widgets) do
            if widget.type == "popupScreen" and widget.name == "playerUi" then
                modules.services.ui:removeWidget(widget.id)
            end
        end
        local mapWidgets = modules.services.ui:getWidgetsByName("playerMapObject"..player.peerId)
        for _, widget in pairs(mapWidgets) do
            if widget.type == "mapObject" then
                modules.services.ui:removeWidget(widget.id)
                modules.services.tracker:destroy(modules.services.tracker:getPlayerTracker(player))
            end
        end

        local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
        for _, group in pairs(vehicles) do
            if not group.isDespawned then
                group:despawn(true)
            end
        end

        modules.libraries.chat:announce("[Player] Leave", string.format("%s (%s) has left the server.", player.name, player.peerId))
    end)

    self.onItemDropConnection = modules.services.player.onItemDrop:connect(function(player, itemObjectId, item)
        if self.playerDespawnDroppedItems then
            local task = modules.services.task:create(self.playerDroppedItemDespawnTime, function(task)
                server.despawnObject(itemObjectId, true)
                modules.services.task:remove(task)
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
                    local groups = table.concat(player:getExtra("groups") or {}, ",")
                    if #groups > 14 then
                        groups = string.sub(groups, 1, 11) .. "..."
                    end
                    if groups == "" then groups = "\n" end
                    widget.text = string.format("[Server]\n[TPS]: %.0f\n[UpTime]: \n%s\n[Player]\n[AS]: %s\n[PVP]: %s\n[Vehicles]:\n%s", modules.services.tps:getTPS(), auscode.utility:formatTime(modules.services.tps._last), (player:getExtra("as") and "True" or "False"), (player:getExtra("pvp") and "True" or "False"), groups)
                    widget:update()
                end
            end
        end
    end, true, false)

    -- player map object ui task
    server.setGameSetting("map_show_players", not self.playerMapObjects)
    self.playerMapUiTask = modules.services.task:create(1, function(task)
        if not self.playerMapObjects then
            modules.services.task:remove(task)
            return
        end

        local players = modules.services.player:getOnlinePlayers()
        for _, player in pairs(players) do
            local widgets = modules.services.ui:getWidgetsByName("playerMapObject"..player.peerId)
            for _, widget in pairs(widgets) do
                if widget.type == "mapObject" then
                    local tracker = modules.services.tracker:getPlayerTracker(player)
                    if tracker then
                        local pos = tracker:getPos()
                        local x,y,z = matrix.position(pos)
                        widget.x = x
                        widget.z = z
                        widget:update()
                    end
                end
            end
        end
    end, true, false)

    for _, player in pairs(modules.services.player:getOnlinePlayers()) do
        self:_verifyUi(player)
    end

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

function auscode.player:createParty(leader)
    local party = modules.classes.party:create(#self.parties+1, leader)
    self.parties[party.id] = party
    return party
end

function auscode.player:saveParty(party)
    self.parties[party.id] = party
    modules.libraries.gsave:saveTable("parties", self.parties)
end

function auscode.player:_verifyUi(player)
    local widgets = modules.services.ui:getPlayersWidgets(player)
    local hasPopup = false
    for _, widget in pairs(widgets) do
        if widget.type == "popupScreen" and widget.name == "playerUi" then
            hasPopup = true
            break
        end
    end

    if not hasPopup then
        local widget = modules.services.ui:createPopupScreen("Loading", -0.9, 0.77, true, player, "playerUi")
        widget:_remove(player)
        widget:update()
        self:toggleUI(player, self.playerDefaultStates.ui)
    end

    if not self.playerMapObjects then return end -- if player map objects are disabled, skip the rest of the function

    -- check map object
    local widgets = modules.services.ui:getWidgetsByName("playerMapObject"..player.peerId)
    if count(widgets) == 0 then
        local tracker = modules.services.tracker:getPlayerTracker(player)
        if not tracker then
            tracker = modules.services.tracker:create(player, 1, false)
        end
        local pos = tracker:getPos()
        local x,y,z = matrix.position(pos)
        table.insert(widgets, modules.services.ui:createMapObject(string.format("%s (%s)",player.name, player.peerId), nil, modules.classes.widgets.color:create(0,255,0), 0, 1, x, z, nil, nil, nil, "playerMapObject"..player.peerId))
    end
end