modules.classes.command = {} -- table of command functions

---@param commandstr string
---@param alias table
---@param description string
---@param func function
---@return Command
function modules.classes.command:create(commandstr, alias, perms, description, func)
    ---@class Command
    local command = {
        _class = "Command",
        commandstr = commandstr,
        alias = alias,
        perms = perms,
        description = description,
        func = func,
        enabled = true,
    }

    -- enables command so it cant get run, defaults to true
    function command:enable()
        self.enabled = true
    end

    -- disables command so it cant get run
    function command:disable()
        self.enabled = false
    end

    -- runs the command
    function command:run(...)
        if self.enabled then
            self.func(...)
        else
            modules.libraries.logging:warning("command:run()", "Command is disabled: '%s'", self.commandstr)
        end
    end

    return command
end