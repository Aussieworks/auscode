modules.classes.widgets.mapLabel = {}

function modules.classes.widgets.mapLabel:create(id, text, labelType, x, z, player, name)
    ---@class MapLabelWidget: Widget
    ---@field text string
    ---@field labelType integer
    ---@field x number
    ---@field z number
    local label = modules.classes.widgets.widget:create(id, player, "mapLabel")
    label._class = "MapLabelWidget"
    label.text = text or ""
    label.labelType = labelType or 0
    label.x = x or 0 -- Default position
    label.z = z or 0 -- Default position
    label.name = name or ""

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

    return label
end