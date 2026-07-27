---@class commandService: Service
---@field commands table<string, Command|string> -- table of commands
modules.services.command = modules.services:createService("command", "Commands Service", {"ChickenMst"})

function modules.services.command:initService()
    self.onInvalidCommand = modules.classes.event:create()

    self.commands = {} -- table of commands
end

function modules.services.command:startService()
    modules.libraries.callbacks:connect("onCustomCommand", function(full_message, peer_id, is_admin, is_auth, command, ...)
        if peer_id == -1 then return end -- ignore server sending commands

        command = self:cleanCommandString(command)

        if not command or command == "" then modules.libraries.logging:info("services.command", "Empty command ignored") return end -- ignore empty commands

        local player = modules.services.player:getPlayerByPeer(peer_id)

        if not player then
            modules.libraries.logging:error("services.command", "Player not found for peer_id: %s | Command: %s", peer_id, command)
            return
        end

        local args = table.pack(...) -- pack the arguments into a table

        self:run(command, full_message, player, args)
    end)
end

-- creates a new command with the inputed command string, alias, description and function
---@param commandstr string main command
---@param alias table<string> aliases for the command
---@param perms table<string> permissions required to run the command
---@param description string description of the command
---@param func fun(player:Player, full_message, command, args, hasPerm)
---@return Command|nil
function modules.services.command:create(commandstr, alias, perms, description, func)
    commandstr = self:cleanCommandString(commandstr) -- clean command string
    -- check if command already exists
    if self.commands[commandstr] then
        modules.libraries.logging:warning("services.command", "Command already exists: %s", commandstr)
        return
    end

    -- check if alias is a table
    if type(alias) ~= "table" then
        modules.libraries.logging:warning("services.command", "Alias is not a table, aborting command creation")
        return
    end

    for _, a in pairs(alias) do
        if a == commandstr then
            modules.libraries.logging:warning("services.command", "Alias: '%s' can't be the same as command | aborting command creation", a, commandstr)
            return
        end

        if self.commands[a] then
            modules.libraries.logging:warning("services.command", "Alias: '%s' can't be the same as another command | aborting command creation", a)
            return
        end
    end

    -- if didnt return false, create command
    local command = modules.classes.command:create(commandstr, alias, perms, description, func)
    modules.libraries.logging:debug("services.command", "Command created: %s", commandstr)

    self.commands[commandstr] = command -- add command to table

    for _, a in pairs(alias) do
        self.commands[a] = commandstr -- add alias to table
    end

    return command
end

-- enables command so it can get run, by default when created it is enabled
---@param commandstr string
function modules.services.command:enable(commandstr)
    if type(self.commands[commandstr]) == "string" then
        modules.libraries.logging:error("services.command", "Attempted to enable command via alias: %s | Aborting", self.commands[commandstr])
        return false
    end

    if self.commands[commandstr] then
        self.commands[commandstr]:enable()
        modules.libraries.logging:debug("services.command", "Command enabled: %s", commandstr)
        return true
    else
        modules.libraries.logging:warning("services.command", "Command not found: %s", commandstr)
        return false
    end
end

-- disables command so it cant get run
---@param commandstr string
function modules.services.command:disable(commandstr)
    if type(self.commands[commandstr]) == "string" then
        modules.libraries.logging:error("services.command", "Attempted to disable command via alias: %s | Aborting", self.commands[commandstr])
        return false
    end

    if self.commands[commandstr] then
        self.commands[commandstr]:disable()
        modules.libraries.logging:debug("services.command", "Command disabled: %s", commandstr)
        return true
    else
        modules.libraries.logging:warning("services.command", "Command not found: %s", commandstr)
        return false
    end
end

-- removes command
---@param commandstr string
function modules.services.command:remove(commandstr)
    if type(self.commands[commandstr]) == "string" then
        modules.libraries.logging:error("services.command", "Attempted to remove command via alias: %s | Aborting", self.commands[commandstr])
        return false
    end

    if self.commands[commandstr] then
        self.commands[commandstr] = nil
        modules.libraries.logging:debug("services.command", "Command removed: %s", commandstr)
        return true
    else
        modules.libraries.logging:warning("services.command", "Command not found: %s", commandstr)
        return false
    end
end

-- runs the command with the inputed command string
---@param command string
---@param full_message string
---@param player Player
---@param args table
function modules.services.command:run(command, full_message, player, args)
    local cmd = self:getCommand(command)
    if cmd == nil then
        modules.libraries.logging:info("services.command", "Command not found: %s", command)
        self.onInvalidCommand:fire(command, full_message, player, args)
        return
    end

    local hasPerm = false
    for _,perm in pairs(cmd.perms) do
        modules.libraries.logging:debug("services.command", "Checking permission: %s for command: %s", perm, command)
        if (player and player:hasPerm(perm)) then
            modules.libraries.logging:debug("services.command", "Player has permission: %s for command: %s", perm, command)
            hasPerm = true
            break
        end
    end

    cmd:run(player, full_message, command, args, hasPerm)
end

-- gets command by command string or alias, returns nil if not found
---@param command string
---@return Command|nil
function modules.services.command:getCommand(command)
    if type(self.commands[command]) == "string" then
        return self.commands[self.commands[command]] -- get the actual command string from the alias
    else
        return self.commands[command] -- get the command directly
    end
end

-- gets all commands
---@return table<string, Command>
function modules.services.command:getCommands()
    return modules.libraries.table:strip(self.commands, "string", true) -- remove all aliases from the table
end

---@param player Player
---@param command Command
---@return boolean
function modules.services.command:hasPerm(player, command)
    local hasPerm = false

    if #command.perms == 0 then
        return true
    end

    for _,perm in pairs(command.perms) do
        modules.libraries.logging:debug("services.command", "Checking permission: %s for command: %s", perm, command.commandstr)
        if (player and player:hasPerm(perm)) then
            modules.libraries.logging:debug("services.command", "Player has permission: %s for command: %s", perm, command.commandstr)
            hasPerm = true
            break
        end
    end

    return hasPerm
end

-- removes ? from command
---@param command string
---@return string
function modules.services.command:cleanCommandString(command)
    local cleaned = command:lower():gsub("^%?", "")
    return cleaned
end