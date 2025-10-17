---@diagnostic disable: lowercase-global
auscode = {} -- main table for auscode

require "modules" -- load modules framework

modules.onStart:connect(function()
    modules.libraries.chat:announce("AusCode", "Hello from AusCode!")

    require "auscode.player"
    require "auscode.commands"
    require "auscode.vehicle"
end)