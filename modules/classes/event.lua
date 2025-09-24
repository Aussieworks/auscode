modules.classes.event = {} -- table of event functions

---@return Event
function modules.classes.event:create()
    ---@class Event
    local event = {
        _class = "Event",
        currentId = 0,
        connections = {},---@type EventConnection[]
        connectionsOrder = {},
        connectionsToRemove = {},
        connectionsToAdd = {},
        isFireing = false,
        hasFiredOnce = false,
    }

    -- connects a callback to the event, creates a new connection and adds it to the connections table
    ---@param callback function
    ---@return EventConnection
    function event:connect(callback)
        self.currentId = self.currentId + 1

        local connection = modules.classes.connection:create(callback)
        self.connections[self.currentId] = connection

        connection.parentEvent = self
        connection.connected = false
        connection.id = self.currentId
        connection.index = -1

        if self.isFireing then
            table.insert(self.connectionsToAdd, connection)
        else
            self:_connectionFinalize(connection)
        end

        return connection
    end

    -- finalizes the connection by adding it to the connectionsOrder and setting its index
    ---@param connection EventConnection
    function event:_connectionFinalize(connection)
        table.insert(self.connectionsOrder, connection.id)

        connection.index = #self.connectionsOrder
        connection.connected = true
    end

    -- disconnects the connection after it has been fired once
    ---@param callback function
    ---@return EventConnection
    function event:once(callback)
        local connection

        connection = self:connect(function(...)
            callback(...)
            connection:disconnect()
        end)

        return connection
    end

    -- disconnects the connection, if it is currently firing, it will be added to the connectionsToRemove table to be removed after firing
    ---@param connection EventConnection
    function event:disconnect(connection)
        if self.isFireing then
            table.insert(self.connectionsToRemove, connection)
        else
            self:_disconnectImidiate(connection)
        end
    end

    -- disconnects the connection immediately, removes it from the connections table and updates the connectionsOrder
    ---@param connection EventConnection
    function event:_disconnectImidiate(connection)
        self.connections[connection.id] = nil
        table.remove(self.connectionsOrder, connection.index)

        for i = connection.index, #self.connectionsOrder do
            local _connection = self.connections[self.connectionsOrder[i]]
            _connection.index = _connection.index - 1
        end

        connection.connected = false
        connection.parentEvent = nil
        connection.id = nil
        connection.index = nil
    end

    -- fires the event, iterates through all connections and calls their fire method
    function event:fire(...)
        self.isFireing = true

        for _, connectionId in ipairs(self.connectionsOrder) do
            local connection = self.connections[connectionId]
            local result = connection:fire(...)

            if result == modules.libraries.event.removeConnection then
                self:disconnect(connection)
            end
        end

        self.isFireing = false

        for i = #self.connectionsToRemove, 1, -1 do
            self:_disconnectImidiate(self.connectionsToRemove[i])
            self.connectionsToRemove[i] = nil
        end

        for i = 1, #self.connectionsToAdd do
            self:_connectionFinalize(self.connectionsToAdd[i])
            self.connectionsToAdd[i] = nil
        end

        self.hasFiredOnce = true
    end

    return event
end