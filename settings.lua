local settings = {
    -- Logging settings
    loggingLevel = {value = 2, default = 4}, -- Default log level set to ERROR
    loggingDetail = {value = "minimal", default = "full"}, -- Default logging detail set to full
    loggingMode = {value = "chat", default = "chat"}, -- Default logging mode set to chat
    targetTPS = {value = 0, default = 0}, -- Target TPS (ticks per second), 0 means no limiting
    -- AusCode settings
    auscodeSafeMode = {value = false, default = false}, -- If AusCode should start in safe mode (use default settings)
    auscodeRestartOnError = {value = false, default = false}, -- If AusCode should try to recover from errors (currently not implemented)
    auscodeDisabledCommands = {value = {}, default = {}}, -- List of disabled commands
    auscodeRules = {value = "Not Set", default = "Not Set"},
    auscodeDiscordLink = {value = "", default = ""}, -- Discord link for the server
    -- Player settings
    auscodePlayerPermissions = {value = {
        ["76561199240115313"]={"admin","owner"},
    }, default = {}}, -- List of players and their permissions (by SteamID)
    auscodePlayerDefaultStates = {value = {as=true,pvp=false,ui=true}, default = {as=true,pvp=false,ui=true}}, -- Default player states
    auscodePlayerItemLookup = {value = {}, default = {}}, -- Lookup table for player items, used to convert string item names to their actual item IDs
    auscodePlayerDefaultItems = {value = {
        [2]={15, false, 0, 100},
        [3]={6, false, 0, 1},
    }, default = {}}, -- List of default items to give to players on spawn, format: [slot]={itemId, bool, int, float}
    auscodePlayerPVPEffects = {value = true, default = true}, -- If player pvp effects should be enabled
    auscodePlayerDespawnDroppedItems = {value = true, default = true}, -- If dropped items should despawn
    auscodePlayerDroppedItemDespawnTime = {value = 20, default = 20}, -- Time in seconds for dropped items to despawn
    -- Vehicle settings
    auscodeVehicleMapObjects = {value = true, default = true}, -- If custom vehicle map objects should be created
    auscodeVehicleAllowWorkshop = {value = true, default = true}, -- If players should be allowed to spawn workshop vehicles
}

return settings