---@class TrackerService : Service
modules.services.tracker = modules.services:createService("tracker", "Handles position tracking for players and vehicles", {"ChickenMst"})

function modules.services.tracker:initService()
    self.trackers = {} -- table of trackers

    self.trackerTasks = {} -- table of tracker tasks

    self.playerTrackerIndex = {}

    self.vehicleTrackerIndex = {}
end

function modules.services.tracker:startService()
end

--- create a position tracker
---@param target Player|Vehicle
---@param updateFrequency number
---@param useTime boolean
---@return Tracker|nil
function modules.services.tracker:create(target, updateFrequency, useTime)
    local id = #self.trackers+1

    if target._class == "Player" then
        self.playerTrackerIndex[target.peerId] = id
    elseif target._class == "Vehicle" then
        self.vehicleTrackerIndex[target.id] = id
    else
        modules.libraries.logging:error("services.tracker:create","Invalid target for tracker: "..target._class)
        return nil
    end

    local tracker = modules.classes.tracker:create(id, target, updateFrequency, useTime)
    self.trackers[id] = tracker

    self.trackerTasks[id] = modules.services.task:create(tracker.updateFrequency, function()
        tracker:update()
    end, true, tracker.useTime)

    return tracker
end

--- get tracker by id
---@param id number
---@return Tracker|nil
function modules.services.tracker:getTracker(id)
    return self.trackers[id]
end

--- get tracker by player
---@param player Player
---@return Tracker|nil
function modules.services.tracker:getPlayerTracker(player)
    if not self.playerTrackerIndex[player.peerId] then
        return nil
    end
    return self.trackers[self.playerTrackerIndex[player.peerId]]
end

--- get tracker by vehicle
---@param vehicle Vehicle
---@return Tracker|nil
function modules.services.tracker:getVehicleTracker(vehicle)
    if not self.vehicleTrackerIndex[vehicle.id] then
        return nil
    end
    return self.trackers[self.vehicleTrackerIndex[vehicle.id]]
end

function modules.services.tracker:_updateTracker(tracker)
    self.trackers[tracker.id] = tracker
end