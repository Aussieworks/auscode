require "modules"

modules.onStart:connect(function()
    modules.libraries.chat:announce("AusCode", "Hello from AusCode!")

    modules.services.player.onJoin:connect(function(player)
        modules.libraries.chat:announce("AusCode", "Welcome " .. player.name .. "!")
    end)

    modules.services.command:create("simjoin", {"sj"}, {}, "simulate a player join", function(player, full_message, command, args, hasPerm)
        onPlayerJoin(981627940718983, "SimulatedPlayer", 100, false, false)
    end)

    modules.services.command:create("loglevel", {"ll"}, {}, "set log level", function(player, full_message, command, args, hasPerm)
        modules.libraries.logging:setLogLevel(args[1] or "DEBUG")
    end)
end)