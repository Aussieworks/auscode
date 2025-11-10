local settings = {
    -- Logging settings
    loggingLevel = {value = 2, default = 4}, -- Default log level set to ERROR
    loggingDetail = {value = "minimal", default = "full"}, -- Default logging detail set to full
    -- AusCode settings
    auscodeSafeMode = {value = false, default = false}, -- If AusCode should start in safe mode (use default settings)
    auscodeRestartOnError = {value = false, default = false}, -- If AusCode should try to recover from errors
    auscodeDisabledCommands = {value = {"runas"}, default = {}}, -- List of disabled commands
}

return settings