modules.classes.widgets.popupScreen = {}

---@return PopupScreenWidget
function modules.classes.widgets.popupScreen:create(id, visible, text, x, y, player, name)
    ---@class PopupScreenWidget
    ---@field type string
    ---@field player Player|nil
    ---@field id integer
    ---@field visible boolean
    ---@field text string
    ---@field x number
    ---@field y number
    local screen = {
        _class = "PopupScreenWidget",
        type = "popupScreen",
        playerId = player and player.steamId or nil,
        id = id,
        visible = visible or false,
        text = text or "",
        x = x or 0, -- Default horizontal position
        y = y or 0, -- Default vertical position
        name = name or ""
    }

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

    -- update the ui object
    function screen:update()
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
    function screen:destroy()
        if self.playerId then
            local player = modules.services.player:getPlayer(self.playerId)
            self:_destroy(player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
            end
        end
    end

    function screen:save()
        modules.services.ui:_addWidget(self)
    end

    return screen
end