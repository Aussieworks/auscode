modules.classes.widgets.mapObject = {}

---@return MapObjectWidget
function modules.classes.widgets.mapObject:create(id, label, hoverLabel, color, posType, markerType, x, z, parentId, player, radius, name)
    ---@class MapObjectWidget
    ---@field type string
    ---@field player Player|nil
    ---@field id integer
    ---@field label string
    ---@field hoverLabel string
    ---@field color Color
    ---@field posType integer
    ---@field markerType integer
    ---@field x number
    ---@field z number
    ---@field radius number
    ---@field parentId number
    local map = {
        _class = "MapObjectWidget",
        type = "mapObject",
        playerId = player and player.steamId or nil,
        id = id,
        label = label or "",
        hoverLabel = hoverLabel or "",
        color = color or modules.classes.widgets.color:create(),
        posType = posType or 0,
        markerType = markerType or 0,
        x = x or 0, -- Default position
        z = z or 0, -- Default position
        radius = radius or 0,
        parentId = parentId or 0,
        name = name or ""
    }

    -- update the ui object for the player
    ---@param player Player|nil
    function map:_update(player)
        server.addMapObject(player and player.peerId or -1, self.id, self.posType, self.markerType, self.x, self.z, self.x, self.z, (self.posType == 1 and self.parentId or 0), (self.posType == 2 and self.parentId or 0), self.label, self.radius, self.hoverLabel, self.color.r, self.color.g, self.color.b, self.color.a)
    end

    -- remove the ui object from the player
    ---@param player Player|nil
    function map:_destroy(player)
        server.removeMapObject(player and player.peerId or -1, self.id)
    end

    -- update the ui object
    function map:update()
        if self.playerId then
            local player = modules.services.player:getPlayer(self.playerId)
            self:_destroy(player)
            self:_update(player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
                self:_update(player)
            end
        end
    end

    -- destroy the ui object
    function map:destroy()
        if self.playerId then
            local player = modules.services.player:getPlayer(self.playerId)
            self:_destroy(player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
            end
        end
    end

    function map:save()
        modules.services.ui:_addWidget(self)
    end

    return map
end