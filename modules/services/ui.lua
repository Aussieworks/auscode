---@class uiService: Service
modules.services.ui = modules.services:createService("ui", "service for handling UI",{"ChickenMst"})

function modules.services.ui:initService()
    self.widgets = {} -- Store all UI widgets
end

function modules.services.ui:startService()
    if modules.addonReason ~= "create" then
        self:_load()
    end

    modules.services.player.onJoin:connect(function(player)
        for _, widget in pairs(self:getPlayersShownWidgets(player)) do
            widget:_update(player)
            self:_save()
        end
    end)

    modules.services.player.onLeave:connect(function(player)
        for _, widget in pairs(self:getPlayersWidgets(player)) do
            self:_removeWidget(widget)
            self:_save()
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
        modules.libraries.logging:warning("services.ui", "Widget with ID '%s' does not exist", id)
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
    self:_save()
end

-- internal function to remove a widget from the service
function modules.services.ui:_removeWidget(widget)
    self.widgets[widget.id] = nil
    self:_save()
end

-- creates a popup screen widget
---@param text string The text to display in the popup
---@param x number The horizontal position of the popup (default is 0)
---@param y number The vertical position of the popup (default is 0)
---@param visable boolean Whether the popup should be visible (default is true)
---@param player Player|nil The player to show the popup to (default is nil, which means all players)
function modules.services.ui:createPopupScreen(text, x, y, visable, player, name)
    local id = server.getMapID()
    local widget = modules.classes.widgets.popupScreen:create(id, visable, text, x, y, player, name)

    widget:update()
    self:_addWidget(widget)

    return widget
end

-- creates a popup widget
---@param text string The text to display in the popup
---@param x number|nil The x position in the world or relitive to the parent (default is 0)
---@param y number|nil The y position in the world or relitive to the parent (default is 0)
---@param z number|nil The z position in the world or relitive to the parent (default is 0)
---@param renderDistance number|nil The distance at which the popup is visible (default is 100)
---@param visable boolean|nil Whether the popup should be visible (default is true)
---@param player Player|nil The player to show the popup to (default is nil, which means all players)
---@param vehicleParent Vehicle|nil The vehicle to attach the popup to (default is nil)
---@param objectParent integer|nil The object ID of the object to attach the popup to (default is nil)
function modules.services.ui:createPopup(text, x, y, z, renderDistance, visable, player, vehicleParent, objectParent)
    local id = server.getMapID()
    local widget = modules.classes.widgets.popup:create(id, visable, text, x, y, z, player, renderDistance, vehicleParent, objectParent)

    widget:update()
    self:_addWidget(widget)
    return widget
end

-- creates a map object widget
---@param label string|nil The label to display on the map
---@param hoverLabel string|nil The label to display when hovering over the map object
---@param color Color|nil The color of the map object
---@param posType integer|nil The position type (0 for world position, 1 for relative to vehicle, 2 for relative to object)
---@param markerType integer|nil The type of marker to display
---@param x number|nil The x position in the world or relitive to the parent
---@param z number|nil The z position in the world or relitive to the parent
---@param parentId integer|nil The ID of the parent object or vehicle
---@param player Player|nil The player to show the map object to (default is nil, which means all players)
---@param radius number|nil The radius of the map object (default is 0)
---@return MapObjectWidget
function modules.services.ui:createMapObject(label, hoverLabel, color, posType, markerType, x, z, parentId, player, radius)
    local id = server.getMapID()
    local widget = modules.classes.widgets.mapObject:create(id, label, hoverLabel, color, posType, markerType, x, z, parentId, player, radius)

    widget:update()
    self:_addWidget(widget)

    return widget
end

-- creates a map label widget
---@param text string|nil The text to display on the map label
---@param labelType number|nil The type of label to display
---@param x number|nil The x position in the world
---@param z number|nil The z position in the world
---@param player Player|nil The player to show the map label to (default is nil, which means all players)
---@return MapLabelWidget
function modules.services.ui:createMapLabel(text, labelType, x, z, player)
    local id = server.getMapID()
    local widget = modules.classes.widgets.mapLabel:create(id, text, labelType, x, z, player)

    widget:update()
    self:_addWidget(widget)

    return widget
end

function modules.services.ui:_save()
    modules.libraries.gsave:saveService("ui", self)
end

function modules.services.ui:_load()
    local widgetRebuildIndex = {
        ["popupScreen"] = function(widget)
            return modules.classes.widgets.popupScreen:create(math.floor(widget.id), widget.visible, widget.text, widget.x, widget.y, widget.player, widget.name)
        end,
        ["popup"] = function(widget)
            return modules.classes.widgets.popup:create(math.floor(widget.id), widget.visible, widget.text, widget.x, widget.y, widget.z, widget.player, widget.renderDistance, widget.vehicleParent, widget.objectParent)
        end,
        ["mapObject"] = function(widget)
            return modules.classes.widgets.mapObject:create(math.floor(widget.id), widget.label, widget.hoverLabel, widget.color, widget.posType, widget.markerType, widget.x, widget.z, widget.parentId, widget.player, widget.radius)
        end,
        ["mapLabel"] = function(widget)
            return modules.classes.widgets.mapLabel:create(math.floor(widget.id), widget.text, widget.labelType, widget.x, widget.z, widget.player)
        end
    } -- table of functions to rebuild widgets mapped by widget type
    local service = modules.libraries.gsave:loadService("ui")

    if not service then
        modules.libraries.logging:warning("ui:_load", "Skiped loading ui service, no data found.")
        return
    end

    if service.widgets then
        for _, widget in pairs(service.widgets) do
            if widgetRebuildIndex[widget.type] then
                local rebuiltWidget = widgetRebuildIndex[widget.type](widget)
                rebuiltWidget:update()
                self:_addWidget(rebuiltWidget)
            else
                modules.libraries.logging:warning("ui:_load", "Unknown widget type: '%s'", tostring(widget.type))
            end
        end
    end
end