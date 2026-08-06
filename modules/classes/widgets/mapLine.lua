modules.classes.widgets.mapLine = {}

function modules.classes.widgets.mapLine:create(id, startM, endM, width, color, player, name)
    ---@class MapLineWidget: Widget
    ---@field startM SWMatrix
    ---@field endM SWMatrix
    ---@field width number
    ---@field color Color
    local mapLine = modules.classes.widgets.widget:create(id, player, "mapLine")
    mapLine._class = "MapLineWidget"
    mapLine.startM = startM or matrix.translation(0, 0, 0)
    mapLine.endM = endM or matrix.translation(0, 0, 0)
    mapLine.width = width or 1
    mapLine.color = color or modules.classes.widgets.color:create()
    mapLine.name = name or "mapLine"

    -- update the ui object for the player
    ---@param player Player|nil
    function mapLine:_update(player)
        server.addMapLine(player and player.peerId or -1, self.id, self.startM, self.endM, self.width, self.color.r, self.color.g, self.color.b, self.color.a)
    end

    -- remove the ui object from the player
    ---@param player Player|nil
    function mapLine:_destroy(player)
        server.removeMapLine(player and player.peerId or -1, self.id)
    end

    return mapLine
end