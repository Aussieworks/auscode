---@class TrackerService : Service
modules.services.tracker = modules.services:createService("tracker", "Handles position tracking for players and vehicles", {"ChickenMst"})

function modules.services.tracker:initService()
    self.trackers = {} -- table of trackers

    self.trackerTasks = {} -- table of tracker tasks

    self.playerTrackerIndex = {}

    self.vehicleTrackerIndex = {}
end

function modules.services.tracker:startService()
    self:load()
end

--- create a position tracker
---@param target Player|Vehicle
---@param updateFrequency number
---@param useTime boolean
---@return Tracker
function modules.services.tracker:create(target, updateFrequency, useTime)
    local id = #self.trackers+1

    local targetId = 0

    if target._class == "Player" then
        if self:getPlayerTracker(target) then
            self:destroy(self:getPlayerTracker(target))
        end
        self.playerTrackerIndex[target.steamId] = id
        targetId = target.steamId
    elseif target._class == "Vehicle" then
        if self:getVehicleTracker(target) then
            self:destroy(self:getVehicleTracker(target))
        end
        self.vehicleTrackerIndex[target.id] = id
        targetId = target.id
    end

    local tracker = modules.classes.tracker:create(id, target, targetId, updateFrequency, useTime)
    self.trackers[id] = tracker

    self.trackerTasks[id] = modules.services.task:create(tracker.updateFrequency, function()
        tracker:update()
    end, true, tracker.useTime)

    self:save()

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
    if not self.playerTrackerIndex[player.steamId] then
        return nil
    end
    return self.trackers[self.playerTrackerIndex[player.steamId]]
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

function modules.services.tracker:destroy(tracker)
    if self.trackers[tracker.id] then
        self.trackers[tracker.id] = nil
        modules.services.task:remove(self.trackerTasks[tracker.id])
        self.trackerTasks[tracker.id] = nil
        if tracker.target._class == "Player" then
            self.playerTrackerIndex[tracker.targetId] = nil
        elseif tracker.target._class == "Vehicle" then
            self.vehicleTrackerIndex[tracker.targetId] = nil
        end
    end
end

function modules.services.tracker:save()
    modules.libraries.gsave:saveService("tracker", self)
end

function modules.services.tracker:load()
    local loaded = modules.libraries.gsave:loadService("tracker")
    if loaded ~= nil and loaded.trackers ~= nil then
        self.playerTrackerIndex = loaded.playerTrackerIndex or {}
        self.vehicleTrackerIndex = loaded.vehicleTrackerIndex or {}
        for id, tracker in pairs(loaded.trackers) do
            local target = tracker.target
            if tracker.targetType == "Player" then
                target = modules.services.player:getPlayer(tracker.targetId)
            elseif tracker.targetType == "Vehicle" then
                local group = modules.services.vehicle:getVehicleGroup(tracker.targetId)
                if group then
                    target = group.vehicles[tracker.targetId]
                else
                    goto continue
                end
            end
            if not target then
                goto continue
            end

            self.trackers[id] = modules.classes.tracker:create(id, target, tracker.targetId, tracker.updateFrequency, tracker.useTime)
            self.trackerTasks[id] = modules.services.task:create(tracker.updateFrequency, function()
                self.trackers[id]:update()
            end, true, tracker.useTime)
            ::continue::
        end
    end
    self:save()
end