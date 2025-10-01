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

modules.services.command:create("test", {}, {}, "test command", function(player, full_message, command, args, hasPerm)

end)