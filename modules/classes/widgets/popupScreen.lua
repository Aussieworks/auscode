modules.classes.widgets.popupScreen = {}

---@return PopupScreenWidget
function modules.classes.widgets.popupScreen:create(id, visible, text, x, y, player, name)
    ---@class PopupScreenWidget: Widget
    ---@field visible boolean
    ---@field text string
    ---@field x number
    ---@field y number
    local screen = modules.classes.widgets.widget:create(id, player, "popupScreen")
    screen._class = "PopupScreenWidget"
    screen.visible = visible or false
    screen.text = text or ""
    screen.x = x or 0 -- Default horizontal position
    screen.y = y or 0 -- Default vertical position
    screen.name = name or ""

    -- update the ui object for the player
    ---@param player Player|nil
    function screen:_update(player)
        server.setPopupScreen(player and player.peerId or -1, self.id, "", self.visible, self.text, self.x, self.y)
    end

    -- remove the ui object from the player
    ---@param player Player|nil
    function screen:_destroy(player)
        server.setPopupScreen(player and player.peerId or -1, self.id, "", false, "", 0, 0)
    end

    -- remove the ui object from the player
    ---@param player Player|nil
    function screen:_remove(player)
        server.removePopup(player and player.peerId or -1, self.id)
    end

    return screen
end