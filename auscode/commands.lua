---@class ACCommands: ACModule
auscode.commands = auscode.classes.module:create("commands", {"ChickenMst"}, "module for auscode's commands") -- command related functions

function auscode.commands:_init(safeMode)
    self.disabledCommands = modules.libraries.settings:getValue("auscodeDisabledCommands", true, {})

    self.onCommandCreation = modules.classes.event:create() -- event to be used for additional command creation

    self.commandList = {} -- list of created commands

    if safeMode then
        self.disabledCommands = modules.libraries.settings:getDefault("auscodeDisabledCommands")
    end

    return true -- return if init successful
end

function auscode.commands:_start(safeMode)
    self:_createCommands()

    return true -- return if start successful
end

function auscode.commands:_cleanup()
    for _, command in pairs(self.commandList) do
        modules.services.command:remove(command.commandstr)
    end
end

---@param command Command|nil
function auscode.commands:add(command)
    if type(command) == "nil" then
        return
    end
    self.commandList[command.commandstr] = command
end

function auscode.commands:_createCommands()
    self:add(modules.services.command:create("simjoin", {"sj"}, {}, "simulate a player join", function(player, full_message, command, args, hasPerm)
        onPlayerJoin(981627940718983, "SimulatedPlayer", 100, false, false)
    end))

    self:add(modules.services.command:create("loglevel", {"ll"}, {}, "set log level", function(player, full_message, command, args, hasPerm)
        modules.libraries.logging:setLogLevel(args[1] or "DEBUG")
    end))

    self:add(modules.services.command:create("antisteal", {"as"}, {}, "toggle antisteal status", function(player, full_message, command, args, hasPerm)
        auscode.player:toggleAntisteal(player)
        player:notify("Anti-Steal", "Anti-Steal has been set to "..tostring(player:getExtra("as")), (player:getExtra("as") and 5 or 6))
    end))

    self:add(modules.services.command:create("pvp", {}, {}, "toggle pvp status", function(player, full_message, command, args, hasPerm)
        auscode.player:togglePVP(player)
        player:notify("PVP", "PVP has been set to "..tostring(player:getExtra("pvp")), (player:getExtra("pvp") and 5 or 6))
    end))

    self:add(modules.services.command:create("clear", {"clean","c","despawn","remove"}, {}, "clear all players vehicles", function(player, full_message, command, args, hasPerm)
        local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
        if #vehicles > 0 then
            local worked = false
            for _, group in pairs(vehicles) do
                if #args > 0 and group.groupId == args[1] then
                    group:despawn(true)
                    worked = true
                    break
                elseif #args == 0 then
                    group:despawn(true)
                    worked = true
                end
            end
            if worked then
                player:notify("Vehicle", "Your vehicle/s have been despawned.", 5)
            else
                player:notify("Vehicle", "No vehicle found with that group ID.", 6)
            end
        else
            player:notify("Vehicle", "You have no vehicle/s to despawn.", 6)
        end
    end))

    self:add(modules.services.command:create("runas", {"ra"}, {}, "run command as another player", function(player, full_message, command, args, hasPerm)
        local targetPlayer = modules.services.player:getPlayerByPeer(args[1])

        if targetPlayer then
            local commandStr = modules.services.command:cleanCommandString(args[2])
            local newArgs = {}
            for i = 3, #args do
                table.insert(newArgs, args[i])
            end
            local full_command = commandStr.." "..table.concat(newArgs, " ")
            modules.services.command:run(commandStr, full_command, targetPlayer, newArgs)
        end
    end))

    self:add(modules.services.command:create("test", {}, {}, "test command", function(player, full_message, command, args, hasPerm)
        modules.services:getService("ui")
    end))

    self:add(modules.services.command:create("ui", {}, {}, "test command", function (player, full_message, command, args, hasPerm)
		if args[1] == "clear" then
			local widgets = modules.services.ui:getPlayersShownWidgets(player)
			for _, widget in pairs(widgets) do
				widget:destroy()
				modules.services.ui:removeWidget(widget.id)
			end
			return
		elseif args[1] == "list" then
			local widgets = modules.services.ui:getPlayersShownWidgets(player)
			local str = "Widgets:\n"
			for _, widget in pairs(widgets) do
				str = str .. "ID: " .. widget.id .. ", Type: " .. widget.type .. ", Player: " .. (widget.player and widget.player.name or "Nil") .. "\n"
			end
			modules.libraries.logging:info("ui", str)
			return
		elseif args[1] == "toggle" then
			auscode.player:toggleUI(player)
        elseif args[1] == "create" then
            local w = modules.services.ui:createPopupScreen("Loading", 0, 0, player:getExtra("ui"), player)
		end
	end))


    self.onCommandCreation:fire()

    -- disable commands from setting `auscodeDisabledCommands`
    for _, cmd in pairs(self.disabledCommands) do
        modules.services.command:disable(cmd)
    end
end