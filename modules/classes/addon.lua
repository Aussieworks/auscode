modules.classes.addon = {} -- table of addon functions

---@param name string
---@param version string|number
---@param authors table<string>
---@param description string
---@return Addon
function modules.classes.addon:create(name, version, description, authors)
    ---@class Addon
    ---@field initAddon function
    ---@field startAddon function
    local addon = {
        _class = "Addon",
        name = name,
        version = version,
        authors = authors,
        description = description,
        enabled = true,
        connections = {}, ---@type table<any, EventConnection>
        commands = {}, ---@type table<string, Command>

        hasInit = false,
        hasStarted = false
    }

    -- enables the addon so it can get run
    function addon:enable()
        self.enabled = true
    end

    -- disables addon so it doesnt get run
    function addon:disable()
        self:removeConnections() -- remove all connections of the addon
        self:removeCommands() -- remove all commands of the addon
        self.hasStarted = false -- reset the started state
        self.enabled = false
    end

    -- initializes the addon, runs the init function of the addon
    function addon:_init()
        if not self.enabled then
            modules.libraries.logging:debug("addon:_init()", "Addon '" .. self.name .. "' is disabled, skipping initialization.")
            return
        end

        if self.hasInit then
            modules.libraries.logging:warning("addon:_init()", "Addon '" .. self.name .. "' is already initialized.")
            return
        end

        modules.libraries.logging:debug("addon:_init()", "Initializing addon '" .. self.name .. "'")
        self.hasInit = true

        if not self.initAddon then
            return
        end

        self:initAddon() -- run the init function of the addon
        return true
    end

    -- starts the addon, runs the start function of the addon
    function addon:_start()
        if not self.enabled then
            modules.libraries.logging:debug("addon:_start()", "Addon '" .. self.name .. "' is disabled, skipping start.")
            return
        end

        if self.hasStarted then
            modules.libraries.logging:warning("addon:_start()", "Attempted to start addon '" .. self.name .. "' that is already started.")
            return
        end

        if not self.hasInit then
            modules.libraries.logging:error("addon:_start()", "Attempted to start addon '" .. self.name .. "' that is not initialized.")
            return
        end

        self.hasStarted = true

        if not self.startAddon then
            return
        end

        self:startAddon() -- run the start function of the addon
        return true
    end

    -- adds a event connection into the addon so it can be removed if the addon is disabled
    ---@param connection EventConnection|nil
    function addon:addConnection(connection)
        if connection then
            table.insert(self.connections, connection)
        end
    end

    -- removes all connections of the addon, disconnects them and removes them from the connections table
    function addon:removeConnections()
        for i, connection in pairs(self.connections) do
            connection:disconnect() -- disconnect the connection
            self.connections[i] = nil -- remove the connection from the connections table
        end
    end

    -- adds a command into the addon so it can be removed if the addon is disabled
    ---@param command Command|nil
    function addon:addCommand(command)
        if command then
            table.insert(self.commands, command) -- add the command to the addon
        end
    end

    -- removes all commands of the addon, removes them from the commands table
    function addon:removeCommands()
        for i, command in pairs(self.commands) do
            modules.services.command:remove(command.commandstr) -- remove the command from the commands table
            self.commands[i] = nil -- remove the command from the addon
        end
    end

    return addon
end