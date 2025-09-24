modules.classes.connection = {} -- table of functions to make event connection class

---@param callback function
---@return EventConnection
function modules.classes.connection:create(callback)
    ---@class EventConnection
    local connection = {
        _class = "EventConnection",
        callback = callback,
        parentEvent = nil, ---@type Event
        connected = false,
        id = nil,
        index = nil
    }

    -- fires the connections callback
    function connection:fire(...)
        if not self.connected then
            modules.libraries.logging:error("connection:fire()", "Attempting to fire a connection that is not connected")
        end

        return self.callback(...)
    end

    -- disconnects the connection from the parent event
    function connection:disconnect()
        if not self.connected then
            modules.libraries.logging:error("connection:disconnect()", "Attempting to disconnect a connection that is not connected")
        end

        self.parentEvent:disconnect(self)
    end

    return connection
end