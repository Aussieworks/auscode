---@class uiService: Service
modules.services.ui = modules.services:createService("ui", "service for handling UI",{"ChickenMst"})

function modules.services.ui:_init()
    self.widgets = {} -- Store all UI widgets
end

function modules.services.ui:_start()
    modules.services.player.onJoin:connect(function(player)
        for _, widget in pairs(self:getPlayersShownWidgets(player)) do
            widget:_update(player)
        end
    end)

    modules.services.player.onLeave:connect(function(player)
        for _, widget in pairs(self:getPlayersWidgets(player)) do
            self:_removeWidget(widget)
        end
    end)
end

-- returns widgets owned by a player
---@param player Player
function modules.services.ui:getPlayersWidgets(player)
    local widgets = {}

    for _, widget in pairs(self.widgets) do
        if not widget.player then
            goto continue
        end

        if modules.services.player:isSamePlayer(player, widget.player) then
            table.insert(widgets, widget)
        end

        ::continue::
    end

    return widgets
end

-- returns all widgets that are shown to a player
---@param player Player
function modules.services.ui:getPlayersShownWidgets(player)
    local widgets = {}

    for _, widget in pairs(self.widgets) do
        if not widget.player or modules.services.player:isSamePlayer(player, widget.player) then
            table.insert(widgets, widget)
        end
    end

    return widgets
end

-- removes the widget with the given ID from the ui service
---@param id integer
function modules.services.ui:removeWidget(id)
    local widget = self:getWidget(id)

    if not widget then
        modules.libraries.logging:warning("services.ui", "Widget with ID " .. id .. " does not exist")
        return
    end

    widget:destroy()
    self:_removeWidget(widget)
end

-- gets a widget by its ID
---@param id integer
function modules.services.ui:getWidget(id)
    return self.widgets[id]
end

-- internal function to add a widget to the service
function modules.services.ui:_addWidget(widget)
    self.widgets[widget.id] = widget
end

-- internal function to remove a widget from the service
function modules.services.ui:_removeWidget(widget)
    self.widgets[widget.id] = nil
end

-- creates a popup screen widget
---@param text string The text to display in the popup
---@param x number The horizontal position of the popup (default is 0)
---@param y number The vertical position of the popup (default is 0)
---@param visable boolean Whether the popup should be visible (default is true)
---@param player Player|nil The player to show the popup to (default is nil, which means all players)
function modules.services.ui:createPopupScreen(text, x, y, visable, player)
    local id = server.getMapID()
    local widget = modules.classes.widgets.popupScreen:create(id, visable, text, x, y, player)

    widget:update()
    self:_addWidget(widget)

    return widget
end