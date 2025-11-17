local settings = {
    -- Logging settings
    loggingLevel = {value = 2, default = 4}, -- Default log level set to ERROR
    loggingDetail = {value = "minimal", default = "full"}, -- Default logging detail set to full
    loggingMode = {value = "chat", default = "chat"}, -- Default logging mode set to chat
    targetTPS = {value = 0, default = 0}, -- Target TPS (ticks per second), 0 means no limiting
    -- AusCode settings
    auscodeSafeMode = {value = false, default = false}, -- If AusCode should start in safe mode (use default settings)
    auscodeRestartOnError = {value = false, default = false}, -- If AusCode should try to recover from errors
    auscodeDisabledCommands = {value = {}, default = {}}, -- List of disabled commands
}

return settings