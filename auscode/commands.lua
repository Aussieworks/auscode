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
    self.onInvalidCommandConnection = modules.services.command.onInvalidCommand:connect(function(command, full_message, player, args)
        modules.libraries.chat:announce("[Command] Invalid Command:", string.format("Command '%s' not found. Type '?help' for a list of commands.", command), player.peerId)
    end)

    self:_createCommands()

    return true -- return if start successful
end

function auscode.commands:_cleanup()
    for _, command in pairs(self.commandList) do
        modules.services.command:remove(command.commandstr)
    end

    self.onInvalidCommandConnection:disconnect()
end

---@param command Command|nil
function auscode.commands:add(command)
    if type(command) == "nil" then
        return
    end
    self.commandList[command.commandstr] = command
end

function auscode.commands:_createCommands()
    self:add(modules.services.command:create("help", {"h"}, {}, "[command] \n \\ List available commands and usage", function(player, full_message, command, args, hasPerm)
        if args[1] then
            local cmd = modules.services.command:getCommand(args[1])
            if cmd and modules.services.command:hasPerm(player, cmd) then
                modules.libraries.chat:announce("[Command] Help:", string.format("?%s %s\n  \\ Alias: %s", cmd.commandstr, cmd.description, table.concat(cmd.alias, ", ")), player.peerId)
            else
                modules.libraries.chat:announce("[Command] Help:", string.format("Command '%s' not found or you do not have permission to use it.", args[1]), player.peerId)
            end
            return
        end

        local availableCommands = {}

        for _, cmd in pairs(modules.services.command:getComamnds()) do
            if cmd.enabled and modules.services.command:hasPerm(player, cmd) then
                table.insert(availableCommands, string.format("?%s %s", cmd.commandstr, cmd.description))
            end
        end

        modules.libraries.chat:announce("[Command] Help:", string.format("Commands Usage: [optional] {required}\n%s",table.concat(availableCommands, "\n")), player.peerId)
    end))

    self:add(modules.services.command:create("playerinfo", {"pi", "pinfo"}, {"owner", "admin", "mod"}, "{peerId|'all'} \n \\ Get players info", function(player, full_message, command, args, hasPerm)
        if not hasPerm then
            return
        end

        if not args[1] or args[1] ~= "all" and type(tonumber(args[1])) ~= "number" then
            player:notify("[Comamnd] Invalid usage", "Usage: ?playerinfo {peerId|'all'}", 1)
            return
        end

        if args[1] ~= "all" then
            local targetPlayer = modules.services.player:getPlayerByPeer(args[1])

            if targetPlayer == nil then
                player:notify("[Command] Player Info", string.format("Player: %s not found.", args[1]), 6)
                return
            end
            local perms = targetPlayer:getPerms()

            local textPerms = {}

            for perm, _ in pairs(perms) do
                if type(tostring(perm)) == "string" then
                    table.insert(textPerms, perm)
                end
            end

            local warns = targetPlayer:getExtra("warnings") or {}

            local info = string.format("Name: %s\nPeer ID: %s\nSteam ID: %s\nOnline: %s\nAnti-Steal: %s\nPVP: %s\nPermissions: %s\nWarns:%s",
                targetPlayer.name,
                targetPlayer.peerId,
                targetPlayer.steamId,
                tostring(targetPlayer.inGame),
                tostring(targetPlayer:getExtra("as")),
                tostring(targetPlayer:getExtra("pvp")),
                table.concat(textPerms, ", "),
                table.concat(warns, ", ")
            )

            modules.libraries.chat:announce("[Command] PlayerInfo:", info, player.peerId)
            return
        end

        local players = modules.services.player:getPlayers()

        local infoList = {}

        for _, targetPlayer in pairs(players) do
            local info = string.format("Name: %s\nPeer ID: %s\nSteam ID: %s\nOnline: %s",
                targetPlayer.name,
                targetPlayer.peerId,
                targetPlayer.steamId,
                tostring(targetPlayer.inGame)
            )
            table.insert(infoList, info)
        end

        modules.libraries.chat:announce("[Command] PlayerInfo:", table.concat(infoList, "\n\n"), player.peerId)
    end))

    self:add(modules.services.command:create("simjoin", {"sj"}, {"owner"}, "\n \\ Simulate a player join", function(player, full_message, command, args, hasPerm)
        onPlayerJoin(981627940718983, "SimulatedPlayer", 100, false, false)
    end))

    self:add(modules.services.command:create("loglevel", {"ll"}, {"owner"}, "{'debug'|'info'|'warning'|'error'} \n \\ Set log level", function(player, full_message, command, args, hasPerm)
        if not hasPerm then
            return
        end

        modules.libraries.logging:setLogLevel(args[1] or "DEBUG")
    end))

    self:add(modules.services.command:create("antisteal", {"as"}, {}, "\n \\ Toggle your Anti-Steal", function(player, full_message, command, args, hasPerm)
        auscode.player:toggleAntisteal(player)
        player:notify("Anti-Steal", "Anti-Steal has been set to "..tostring(player:getExtra("as")), (player:getExtra("as") and 5 or 6))
    end))

    self:add(modules.services.command:create("pvp", {}, {}, "\n \\ Toggle your PVP", function(player, full_message, command, args, hasPerm)
        auscode.player:togglePVP(player)
        player:notify("PVP", "PVP has been set to "..tostring(player:getExtra("pvp")), (player:getExtra("pvp") and 5 or 6))
    end))

    self:add(modules.services.command:create("clear", {"clean","c","despawn","remove"}, {}, "[groupId] \n \\ Despawn your vehicle/s", function(player, full_message, command, args, hasPerm)
        local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
        if count(vehicles) > 0 then
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

    self:add(modules.services.command:create("clearall", {"cleanall","ca","despawnall","removeall"}, {"owner","admin"}, "\n \\ Despawn all vehicles", function(player, full_message, command, args, hasPerm)
        if not hasPerm then
            return
        end

        local groups = modules.services.vehicle:getAllGroups()

        for _, group in pairs(groups) do
            group:despawn(true)
        end

        player:notify("Vehicle", "All vehicles have been despawned.", 5)
    end))

    self:add(modules.services.command:create("runas", {"ra"}, {"owner"}, "{peerId} {command} [args] \n \\ Run a command as another player", function(player, full_message, command, args, hasPerm)
        if not hasPerm then
            return
        end

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

    self:add(modules.services.command:create("ui", {}, {}, "{'list'|'toggle'|'create'} \n \\ Temporary ui command", function (player, full_message, command, args, hasPerm)
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
				str = str .. "ID: " .. widget.id .. ", Type: " .. widget.type .. ", Player: " .. (widget.playerId or "Nil") .. "\n"
			end
			modules.libraries.logging:info("ui", str)
			return
		elseif args[1] == "toggle" then
			auscode.player:toggleUI(player)
        elseif args[1] == "create" then
            modules.services.ui:createPopupScreen("Loading", -0.9, 0.8, player:getExtra("ui"), player, "playerUi")
		end
	end))

    self:add(modules.services.command:create("purge", {}, {"owner"}, "\n \\ Purge gsave", function (player, full_message, command, args, hasPerm)
        modules.libraries.gsave:_purgeGsave()
    end))

    self:add(modules.services.command:create("auth", {"a"}, {}, "\n \\ Auth", function (player, full_message, command, args, hasPerm)
        player:setAuth(true)
        player:notify("Auth", "You are now authenticated.", 5)
    end))

    self:add(modules.services.command:create("tpp", {}, {}, "{peerId} [peerId]\n \\ Teleport to player", function (player, full_message, command, args, hasPerm)
        if not args[1] or type(tonumber(args[1])) ~= "number" then
            player:notify("[Command] Invalid usage", "Usage: ?tpp {peerId} [peerId]", 6)
            return
        end

        local targetPlayer = modules.services.player:getPlayerByPeer(args[1])

        if not targetPlayer then
            player:notify("TPP", "Player not found.", 1)
            return
        end

        player:setPos(targetPlayer:getPos())
        player:notify("TPP", "Teleported to "..targetPlayer.name, 5)
    end))

    self:add(modules.services.command:create("tpv", {}, {}, "{groupId}\n \\ Teleport to vehicle group", function (player, full_message, command, args, hasPerm)
        if not args[1] or type(tonumber(args[1])) ~= "number" then
            player:notify("[Command] Invalid usage", "Usage: ?tpv {groupId}", 6)
            return
        end

        local group = modules.services.vehicle:getGroup(args[1], true)

        if not group then
            player:notify("TPV", "Vehicle group not found.", 1)
            return
        end

        local firstVehicle

        for _, vehicle in pairs(group.vehicles) do
            firstVehicle = vehicle
            break
        end

        local pos = firstVehicle:getPos()
        local x,y,z = matrix.position(pos)
        pos = matrix.translation(x, y + 5, z)

        player:setPos(pos)
        player:notify("TPV", "Teleported to vehicle group "..group.groupId, 5)
    end))

    self:add(modules.services.command:create("tvp", {}, {}, "{groupId}\n \\ Teleport vehicle group to you", function (player, full_message, command, args, hasPerm)
        if not args[1] or type(tonumber(args[1])) ~= "number" then
            player:notify("[Command] Invalid usage", "Usage: ?tvp {groupId}", 6)
            return
        end

        local group = (hasPerm==true and modules.services.vehicle:getGroup(args[1], true) or (hasPerm==false and modules.services.vehicle:getPlayersVehicleGroups(player, true)[tostring(args[1])]))

        if not group then
            player:notify("TVP", "Vehicle group not found.", 1)
            return
        end

        local pos = player:getPos()
        local x,y,z = matrix.position(pos)
        pos = matrix.translation(x, y + 5, z)

        group:setPos(pos)
        player:notify("TVP", "Teleported vehicle group "..group.groupId.." to you.", 5)
    end))

    self:add(modules.services.command:create("flip", {"f"}, {}, "[groupId]\n \\ Flip vehicle/s upright", function (player, full_message, command, args, hasPerm)
        local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
        if count(vehicles) > 0 then
            local worked = false
            if #args > 0 and vehicles[tostring(args[1])] then
                for _, vehicle in pairs(vehicles[tostring(args[1])].vehicles) do
                    local pos = vehicle:getPos()
                    local x,y,z = matrix.position(pos)
                    pos = matrix.translation(x, y, z)
                    vehicle:setPos(pos)
                end
                worked = true
            elseif #args == 0 then
                for _, group in pairs(vehicles) do
                    for _, vehicle in pairs(group.vehicles) do
                        local pos = vehicle:getPos()
                        local x,y,z = matrix.position(pos)
                        pos = matrix.translation(x, y, z)
                        vehicle:setPos(pos)
                    end
                    worked = true
                end
            end
            if worked then
                player:notify("Vehicle", "Your vehicle/s have been flipped.", 5)
            else
                player:notify("Vehicle", "No vehicle found with that group ID.", 6)
            end
        else
            player:notify("Vehicle", "You have no vehicle/s to flip.", 6)
        end
    end))

    self:add(modules.services.command:create("repair", {"r"}, {}, "[groupId]\n \\ Repair vehicle/s", function (player, full_message, command, args, hasPerm)
        local vehicles = modules.services.vehicle:getPlayersVehicleGroups(player)
        if count(vehicles) > 0 then
            local worked = false
            if #args > 0 and vehicles[tostring(args[1])] then
                vehicles[tostring(args[1])]:resetState()
                worked = true
            elseif #args == 0 then
                for _, group in pairs(vehicles) do
                    group:resetState()
                    worked = true
                end
            end

            if worked then
                player:notify("Vehicle", "Your vehicle/s have been repaired.", 5)
            else
                player:notify("Vehicle", "No vehicle found with that group ID.", 6)
            end
        else
            player:notify("Vehicle", "You have no vehicle/s to repair.", 6)
        end
    end))

    self:add(modules.services.command:create("warn", {"w"}, {"owner", "admin", "mod"}, "{peerId} {reason} \n \\ Warn a player", function (player, full_message, command, args, hasPerm)
        if not hasPerm then
            return
        end

        if not args[1] or type(tonumber(args[1])) ~= "number" or not args[2] then
            player:notify("[Command] Invalid usage", "Usage: ?warn {peerId} {reason}", 6)
            return
        end

        local targetPlayer = modules.services.player:getPlayerByPeer(args[1])

        if not targetPlayer then
            player:notify("Warn", "Player not found.", 1)
            return
        end

        local reason = table.concat(args, " ", 2)

        targetPlayer:notify("Warning", string.format("You have been warned by %s for: %s", player.name, reason), 10)
        player:notify("Warn", string.format("You have warned %s for: %s", targetPlayer.name, reason), 5)

        local warnings = targetPlayer:getExtra("warnings") or {}
        table.insert(warnings, reason)
        targetPlayer:setExtra("warnings", warnings)
        targetPlayer:save()
    end))

    self:add(modules.services.command:create("version", {"ver"}, {}, "\n \\ Show AusCode version", function (player, full_message, command, args, hasPerm)
        modules.libraries.chat:announce("[Command] Version", string.format("AusCode: %s\nModules: %s", auscode.version, modules.version), player.peerId)
    end))

    self:add(modules.services.command:create("rules", {}, {}, "\n \\ Show server rules", function (player, full_message, command, args, hasPerm)
        local rules = modules.libraries.settings:getValue("auscodeRules", true, "Not Set")
        modules.libraries.chat:announce("[Command] Rules", rules, player.peerId)
    end))

    self:add(modules.services.command:create("discord", {"disc"}, {}, "\n \\ Show Discord link", function (player, full_message, command, args, hasPerm)
        local discordLink = modules.libraries.settings:getValue("auscodeDiscordLink", true, "")
        if discordLink ~= "" then
            modules.libraries.chat:announce("[Command] Discord Link", discordLink, player.peerId)
        else
            player:notify("Discord", "No Discord link set.", 6)
        end
    end))

    self:add(modules.services.command:create("message", {"msg","wisper","tell"}, {}, "{playerId} {message}\n \\ Send a private message to a player", function (player, full_message, command, args, hasPerm)
        if not args[1] or not args[2] then
            player:notify("[Command] Invalid usage", "Usage: ?message {playerId} {message}", 6)
            return
        end

        local targetPlayer = modules.services.player:getPlayerByPeer(args[1])

        if not targetPlayer then
            player:notify("Message", "Player not found.", 6)
            return
        end

        local message = table.concat(args, " ", 2)

        modules.libraries.chat:announce("[Message] From: "..player.name, message, targetPlayer.peerId)
        modules.libraries.chat:announce("[Message] To: "..targetPlayer.name, message, player.peerId)
    end))

    self:add(modules.services.command:create("test", {}, {}, "\n \\ Test Command", function (player, full_message, command, args, hasPerm)
        player:notify("Uptime", auscode.utility:formatTime(modules.services.tps._last), 5)
    end))

    self.onCommandCreation:fire()

    -- disable commands from setting `auscodeDisabledCommands`
    for _, cmd in pairs(self.disabledCommands) do
        modules.services.command:disable(cmd)
    end
end