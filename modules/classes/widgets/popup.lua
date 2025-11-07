modules.classes.widgets.popup = {}

---@return PopupWidget
function modules.classes.widgets.popup:create(id, visible, text, x, y, z, player, renderDistance, vehicleParent, objectParent)
    ---@class PopupWidget
    ---@field type string
    ---@field player Player|nil
    ---@field id integer
    ---@field visible boolean
    ---@field text string
    ---@field x number
    ---@field y number
    ---@field z number
    ---@field renderDistance number
    ---@field vehicleParent Vehicle|nil
    ---@field objectParent integer|nil
    local popup = {
        _class = "PopupWidget",
        type = "popup",
        playerId = player and player.steamId or nil,
        id = id,
        visible = visible or true,
        text = text or "",
        x = x or 0, -- Default horizontal position
        y = y or 0, -- Default vertical position
        z = z or 0, -- Default vertical position
        renderDistance = renderDistance or 100, -- Default render distance
        vehicleParent = vehicleParent,
        objectParent = objectParent
    }

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

    -- update the ui object
    function popup:update()
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
    function popup:destroy()
        if self.playerId then
            local player = modules.services.player:getPlayer(self.playerId)
            self:_destroy(player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
            end
        end
    end

    function popup:save()
        modules.services.ui:_addWidget(self)
    end

    return popup
end