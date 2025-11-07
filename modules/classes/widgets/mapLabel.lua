modules.classes.widgets.mapLabel = {}

function modules.classes.widgets.mapLabel:create(id, text, labelType, x, z, player)
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
        player = player,
        id = id,
        text = text or "",
        labelType = labelType or 0,
        x = x or 0, -- Default position
        z = z or 0, -- Default position
    }

    -- update the label for the player
    ---@param player Player
    function label:_update(player)
        server.addMapLabel(player.peerId, self.id, self.labelType, self.text, self.x, self.z)
    end

    -- remove the label from the player
    ---@param player Player
    function label:_destroy(player)
        server.removeMapLabel(player.peerId, self.id)
    end

    -- update the label
    function label:update()
        if self.player then
            self:_destroy(self.player)
            self:_update(self.player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
                self:_update(player)
            end
        end
    end

    -- destroy the label
    function label:destroy()
        if self.player then
            self:_destroy(self.player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
            end
        end
    end

    function label:save()
        modules.services.ui:_save()
    end

    return label
end