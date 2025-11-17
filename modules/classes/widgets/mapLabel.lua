modules.classes.widgets.mapLabel = {}

function modules.classes.widgets.mapLabel:create(id, text, labelType, x, z, player, name)
    ---@class MapLabelWidget
    ---@field type string
    ---@field player Player|nil
    ---@field id number
    ---@field text string
    ---@field labelType integer
    ---@field x number
    ---@field z number
    local label = {
        _class = "MapLabelWidget",
        type = "mapLabel",
        playerId = player and player.steamId or nil,
        id = id,
        text = text or "",
        labelType = labelType or 0,
        x = x or 0, -- Default position
        z = z or 0, -- Default position
        name = name or ""
    }

    -- update the label for the player
    ---@param player Player|nil
    function label:_update(player)
        server.addMapLabel(player and player.peerId or -1, self.id, self.labelType, self.text, self.x, self.z)
    end

    -- remove the label from the player
    ---@param player Player|nil
    function label:_destroy(player)
        server.removeMapLabel(player and player.peerId or -1, self.id)
    end

    -- update the label
    function label:update()
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

    -- destroy the label
    function label:destroy()
        if self.playerId then
            local player = modules.services.player:getPlayer(self.playerId)
            self:_destroy(player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
            end
        end
    end

    function label:save()
        modules.services.ui:_addWidget(self)
    end

    return label
end