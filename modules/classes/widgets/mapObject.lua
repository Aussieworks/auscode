modules.classes.widgets.mapObject = {}

---@return MapObjectWidget
function modules.classes.widgets.mapObject:create(id, label, hoverLabel, color, posType, markerType, x, z, parentId, player, radius, name)
    ---@class MapObjectWidget: Widget
    ---@field label string
    ---@field hoverLabel string
    ---@field color Color
    ---@field posType integer
    ---@field markerType integer
    ---@field x number
    ---@field z number
    ---@field radius number
    ---@field parentId number
    local map = modules.classes.widgets.widget:create(id, player, "mapObject")
    map._class = "MapObjectWidget"
    map.label = label or ""
    map.hoverLabel = hoverLabel or ""
    map.color = color or modules.classes.widgets.color:create()
    map.posType = posType or 0
    map.markerType = markerType or 0
    map.x = x or 0 -- Default position
    map.z = z or 0 -- Default position
    map.radius = radius or 0
    map.parentId = parentId or 0
    map.name = name or ""

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

    return map
end