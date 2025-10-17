auscode.commands = {} -- command related functions


modules.services.command:create("simjoin", {"sj"}, {}, "simulate a player join", function(player, full_message, command, args, hasPerm)
    onPlayerJoin(981627940718983, "SimulatedPlayer", 100, false, false)
end)

modules.services.command:create("loglevel", {"ll"}, {}, "set log level", function(player, full_message, command, args, hasPerm)
    modules.libraries.logging:setLogLevel(args[1] or "DEBUG")
end)

modules.services.command:create("antisteal", {"as"}, {}, "toggle antisteal status", function(player, full_message, command, args, hasPerm)
    auscode.player:toggleAntisteal(player)
    player:notify("Anti-Steal", "Anti-Steal has been set to "..tostring(player:getExtra("as")), (player:getExtra("as") and 5 or 6))
end)

modules.services.command:create("pvp", {}, {}, "toggle pvp status", function(player, full_message, command, args, hasPerm)
    auscode.player:togglePVP(player)
    player:notify("PVP", "PVP has been set to "..tostring(player:getExtra("pvp")), (player:getExtra("pvp") and 5 or 6))
end)

modules.services.command:create("clear", {"clean","c","despawn","remove"}, {}, "clear all players vehicles", function(player, full_message, command, args, hasPerm)
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
end)

modules.services.command:create("runas", {"ra"}, {}, "run command as another player", function(player, full_message, command, args, hasPerm)
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
end)

modules.services.command:create("test", {}, {}, "test command", function(player, full_message, command, args, hasPerm)
    g_savedata = {}
end)