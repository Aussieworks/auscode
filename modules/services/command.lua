---@class commandService: Service
---@field commands table<string, Command> -- table of commands
modules.services.command = modules.services:createService("command", "Commands Service", {"ChickenMst"})

function modules.services.command:initService()
    self.commands = {} -- table of commands
end

function modules.services.command:startService()
    modules.libraries.callbacks:connect("onCustomCommand", function(full_message, peer_id, is_admin, is_auth, command, ...)
        if peer_id == -1 then return end -- ignore server sending commands

        command = self:cleanCommandString(command)

        if not command or command == "" then modules.libraries.logging:info("services.command", "Empty command ignored") return end -- ignore empty commands

        args = table.pack(...) -- pack the arguments into a table
        local player = modules.services.player:getPlayerByPeer(peer_id)
        if self.commands[command] then
            local hasPerm = false
            for _,perm in pairs(self.commands[command].perms) do
                modules.libraries.logging:debug("services.command", "Checking permission: " .. perm .. " for command: " .. command)
                if (player and player:hasPerm(perm)) then
                    modules.libraries.logging:debug("services.command", "Player has permission: " .. perm .. " for command: " .. command)
                    hasPerm = true
                    break
                end
            end
            self.commands[command]:run(player, full_message, command, args, hasPerm)
        elseif not self.commands[command] then
            for _, cmd in pairs(self.commands) do
                for _, alias in pairs(cmd.alias) do
                    if alias == command then
                        cmd:run(player, full_message, command, args)
                        return
                    end
                end
            end
            modules.libraries.logging:warning("services.command", "Command not found: " .. command)
        end
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
    local existing_command = self.commands[commandstr]
    if existing_command then
        modules.libraries.logging:warning("services.command", "Command already exists: " .. commandstr)
        return
    end

    -- check if alias already exists
    if type(alias) == "table" then
        for _, a in pairs(alias) do
            -- check if alias is the same as its command
            if self:cleanCommandString(a) == self:cleanCommandString(commandstr) then
                modules.libraries.logging:warning("services.command", "Alias: "..a.." can't be the same as command: "..commandstr.." | aborting command creation")
                return
            end
            for _, cmd in pairs(self.commands) do
                if type(cmd.alias) == "table" then
                    for _, existing_a in pairs(cmd.alias) do
                        if self:cleanCommandString(a) == self:cleanCommandString(existing_a) then -- check if alias is the same as another alias
                            modules.libraries.logging:warning("services.command", "Alias: "..a.." for command: "..commandstr.." already exists | aborting command creation")
                            return
                        elseif self:cleanCommandString(a) == self:cleanCommandString(cmd.commandstr) then -- check if alias is the same as another command
                            modules.libraries.logging:warning("services.command", "Alias: "..a.." can't be the same as command: "..cmd.commandstr.." | aborting command creation")
                            return
                        end
                    end
                end
            end
        end
    else
        modules.libraries.logging:warning("services.command", "Alias is not a table, aborting command creation")
        return
    end

    -- if didnt return false, create command
    local command = modules.classes.command:create(commandstr, alias, perms, description, func)
    modules.libraries.logging:debug("services.command", "Command created: " .. commandstr)

    self.commands[commandstr] = command -- add command to table

    return command
end

-- enables command so it can get run, by default when created it is enabled
---@param commandstr string
function modules.services.command:enable(commandstr)
    if self.commands[commandstr] then
        self.commands[commandstr]:enable()
        modules.libraries.logging:debug("services.command", "Command enabled: " .. commandstr)
    else
        modules.libraries.logging:warning("services.command", "Command not found: " .. commandstr)
    end
end

-- disables command so it cant get run
---@param commandstr string
function modules.services.command:disable(commandstr)
    if self.commands[commandstr] then
        self.commands[commandstr]:disable()
        modules.libraries.logging:debug("services.command", "Command disabled: " .. commandstr)
    else
        modules.libraries.logging:warning("services.command", "Command not found: " .. commandstr)
    end
end

-- removes command
---@param commandstr string
function modules.services.command:remove(commandstr)
    if self.commands[commandstr] then
        self.commands[commandstr] = nil
        modules.libraries.logging:debug("services.command", "Command removed: " .. commandstr)
    else
        modules.libraries.logging:warning("services.command", "Command not found: " .. commandstr)
    end
end

-- removes ? from command
---@param command string
---@return string
function modules.services.command:cleanCommandString(command)
    local cleaned = command:lower():gsub("^%?", "")
    return cleaned
end