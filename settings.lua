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
    auscodePlayerAutoAuth = {value = true, default = true}, -- If players should be automatically authenticated on load
    auscodePlayerPermissions = {value = {
        ["76561199240115313"]={"admin","owner"},
    }, default = {}}, -- List of players and their permissions (by SteamID) eg {["76561199240115313"]={"admin","owner"}, ["76561199240115314"]={"mod"}}
    auscodePlayerDefaultPermissions = {value = {"player"}, default = {"player"}}, -- Default permissions for players not listed in auscodePlayerPermissions
    auscodePlayerPermissionsWeight = {value = {
        ["owner"]=4,
        ["admin"]=3,
        ["mod"]=2,
        ["player"]=1,
    }, default = {}}, -- Weight of each permission level, used to determine which permission takes precedence when a player has multiple permissions
    auscodePlayerPermissionsTag = {value = {
        ["owner"]="[Owner]",
        ["admin"]="[Admin]",
        ["mod"]="[Mod]",
        ["player"]="[Player]",
    }, default = {}}, -- Tag and for each permission level. used in custom chat
    auscodePlayerDefaultStates = {value = {as=true,pvp=false,ui=true}, default = {as=true,pvp=false,ui=true}}, -- Default player states
    auscodePlayerItemLookup = {value = {}, default = {}}, -- Lookup table for player items, used to convert string item names to their actual item IDs. eg {["scuba"]=1,["medkit"]=11}
    auscodePlayerDefaultItems = {value = {
        [2]={15, false, 0, 100},
        [3]={6, false, 0, 1},
    }, default = {}}, -- List of default items to give to players on spawn, format: [slot]={itemId, bool, int, float}
    auscodePlayerPVPEffects = {value = true, default = true}, -- If player pvp effects should be enabled
    auscodePlayerDespawnDroppedItems = {value = true, default = true}, -- If dropped items should despawn
    auscodePlayerDroppedItemDespawnTime = {value = 10, default = 20}, -- Time in seconds for dropped items to despawn
    auscodePlayerMapObjects = {value = true, default = true}, -- If custom player map objects should be created
    -- Vehicle settings
    auscodeVehicleMapObjects = {value = true, default = true}, -- If custom vehicle map objects should be created
    auscodeVehicleAllowWorkshop = {value = true, default = true}, -- If players should be allowed to spawn workshop vehicles
    auscodeVehicleVoxelLimit = {value = 10000, default = 10000}, -- Maximum number of voxels allowed in a vehicle
    auscodeVehicleSubBodyLimit = {value = 10, default = 10}, -- Maximum number of sub-bodies allowed in a vehicle
    auscodeVehicleTimeLimit = {value = 0, default = 0}, -- Time limit for vehicles spawning in milliseconds, 0 means no time limit
    auscodeVehicleGroupLimit = {value = 1, default = 1}, -- Maximum number of vehicle groups a player can have
    auscodeVehicleBypassChecksPermissions = {value = {"admin","owner"}, default = {"admin","owner"}}, -- Permissions that allow players to bypass vehicle limits
    -- Chat settings
    auscodeChatCustomChat = {value = true, default = true}, -- If custom chat functionality should be enabled
    auscodeChatMessageLimit = {value = 130, default = 130}, -- Maximum number of chat messages to store
    auscodeChatHiddenWords = {value = {}, default = {}}, -- List of words to hide in chat messages eg {"badword1", "badword2"}, requires auscodeChatCustomChat to be true
    auscodeChatHiddenWordReplacement = {value = "*", default = "*"}, -- Character to replace hidden words with
    auscodeChatTips = {value = {}, default = {}}, -- List of tips to display in chat eg: {"Tip 1", "Tip 2"}
    auscodeChatTipFrequency = {value = 0, default = 300}, -- Time in seconds between displaying tips in chat, 0 is off
}

return settings