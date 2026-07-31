modules.classes.widgets.widget = {}

function modules.classes.widgets.widget:create(id, player, type)
    ---@class Widget
    ---@field _destroy function
    ---@field _update function
    local widget = {
        _class = "Widget",
        type = type,
        id = id,
        playerId = player and player.steamId or nil,
    }

        -- update the ui object
    function widget:update()
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
    function widget:destroy()
        if self.playerId then
            local player = modules.services.player:getPlayer(self.playerId)
            self:_destroy(player)
        else
            for _, player in pairs(modules.services.player:getOnlinePlayers()) do
                self:_destroy(player)
            end
        end
    end

    function widget:save()
        modules.services.ui:_addWidget(self)
    end

    return widget
end