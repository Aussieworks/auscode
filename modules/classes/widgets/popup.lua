modules.classes.widgets.popup = {}

---@return PopupWidget
function modules.classes.widgets.popup:create(id, visible, text, x, y, z, player, renderDistance, vehicleParent, objectParent, name)
    ---@class PopupWidget: Widget
    ---@field visible boolean
    ---@field text string
    ---@field x number
    ---@field y number
    ---@field z number
    ---@field renderDistance number
    ---@field vehicleParent Vehicle|nil
    ---@field objectParent integer|nil
    local popup = modules.classes.widgets.widget:create(id, player, "popup")
    popup._class = "PopupWidget"
    popup.visible = visible or true
    popup.text = text or ""
    popup.x = x or 0 -- Default horizontal position
    popup.y = y or 0 -- Default vertical position
    popup.z = z or 0 -- Default vertical position
    popup.renderDistance = renderDistance or 100 -- Default render distance
    popup.vehicleParent = vehicleParent
    popup.objectParent = objectParent
    popup.name = name or ""

    -- update the ui object for the player
    ---@param player Player|nil
    function popup:_update(player)
        server.setPopup(player and player.peerId or -1, self.id, "", self.visible, self.text, self.x, self.y, self.z, self.renderDistance, (self.vehicleParent and self.vehicleParent.id or nil), self.objectParent)
    end

    -- remove the ui object from the player
    ---@param player Player|nil
    function popup:_destroy(player)
        server.setPopup(player and player.peerId or -1, self.id, "", false, "", 0, 0, 0, 0)
    end

    return popup
end