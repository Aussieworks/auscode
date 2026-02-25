---@class ACUtility: ACModule
auscode.utility = auscode.classes.module:create("utility", {"ChickenMst"}, "module for auscode's utility functions")

function auscode.utility:_init(safeMode)
    return true
end

function auscode.utility:_start(safeMode)
    return true
end

function auscode.utility:formatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60
	return string.format("%dh %dm %ds", hours, minutes, seconds)
end