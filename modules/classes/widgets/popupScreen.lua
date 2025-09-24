modules.classes.widgets.popupScreen = {}

---@return PopupScreenWidget
function modules.classes.widgets.popupScreen:create(id, visible, text, x, y, player)
    ---@class PopupScreenWidget
    ---@field player Player|nil
    ---@field id integer
    ---@field name string
    ---@field visible boolean
    ---@field text string
    ---@field x number
    ---@field y number
    local screen = {
        _class = "PopupScreenWidget",
        player = player,
        id = id,
        visible = visible or true,
        text = text or "",
        x = x or 0, -- Default horizontal position
        y = y or 0, -- Default vertical position
    }

    -- update the ui object for the player
    ---@param player Player
    function screen:_update(player)
        server.setPopupScreen(player.peerId, self.id, "", self.visible, self.text, self.x, self.y)
    end

    -- remove the ui object from the player
    ---@param player Player
    function screen:_destroy(player)
        server.setPopupScreen(player.peerId, self.id, "", false, "", 0, 0)
    end

    -- update the ui object
    function screen:update()
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

    -- destroy the ui object
    function screen:destroy()
        if self.player then
            self:_destroy(self.player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
            end
        end
    end

    return screen
end