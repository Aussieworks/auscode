---@class objectService : Service
modules.services.object = modules.services:createService("object", "Handles object data and events", {"ChickenMst"})

function modules.services.object:initService()
    self.onSpawnEvents = {} -- table of events for when an object is spawned
    self.onLoadEvents = {} -- table of events for when an object is loaded
    self.onUnloadEvents = {} -- table of events for when an object is unloaded

    self.spawnedObjectIndex = {}
    self.loadedObjectIndex = {}

    self.objects = {} -- table of all objects, indexed by object_id

    self._lastObjectId = 0
    self.objectSpawnCheck = modules.libraries.settings:getValue("objectSpawnCheck", true, true)
end

function modules.services.object:startService()
    if modules.addonReason ~= "create" then
        self:_load()
        self:_verifyObjectStates()
    end

    modules.libraries.callbacks:connect("onObjectLoad", function(object_id)
        if not self.objects[object_id] then -- if the object class doesn't exist, create it
            self.objects[object_id] = modules.classes.object:create(object_id)
        end

        if self.spawnedObjectIndex[object_id] then -- if the object was tracked as spawned, remove it from the spawned index
           self.spawnedObjectIndex[object_id] = nil
        end

        table.insert(self.loadedObjectIndex, object_id) -- add the object to the loaded index

        local object = self.objects[object_id]
        local objectData = server.getObjectData(object_id)

        if self.onLoadEvents[objectData.object_type] then
            modules.libraries.logging:debug("services.object", "Firing onLoad event for object type: %s", objectData.object_type)
            self.onLoadEvents[objectData.object_type]:fire(object, objectData)
        end
    end)

    modules.libraries.callbacks:connect("onObjectUnload", function(object_id)
        if not self.objects[object_id] then -- if the object class doesn't exist, create it
            self.objects[object_id] = modules.classes.object:create(object_id)
        end

        if self.loadedObjectIndex[object_id] then -- if the object was tracked as loaded, remove it from the loaded index
            self.loadedObjectIndex[object_id] = nil
        end

        local object = self.objects[object_id]
        local objectData = server.getObjectData(object_id)

        if self.onUnloadEvents[objectData.object_type] then
            modules.libraries.logging:debug("services.object", "Firing onUnload event for object type: %s", objectData.object_type)
            self.onUnloadEvents[objectData.object_type]:fire(object, objectData)
        end

        self.objects[object_id] = nil -- remove the object from the objects table
        self:_save() -- save the service state after an object is unloaded
    end)

    if self.objectSpawnCheck then
        modules.services.task:create(1, function()
            self:_checkForSpawnedObjects()
            self:_save()
        end, true, false)
    end
end

function modules.services.object:findCurrentObjectId()
    local currentId, worked = server.spawnObject(matrix.identity(), 0)
    server.despawnObject(currentId, true)

    if not worked then
        modules.libraries.logging:error("services.object", "Failed to spawn object to find current id")
        return nil
    end
    return currentId
end

function modules.services.object:_checkForSpawnedObjects()
    local startId = self._lastObjectId + 1
    local endId = self:findCurrentObjectId()

    for objectId = startId, endId do
        self:_checkIfSpawnedObject(objectId)
    end

    self._lastObjectId = endId
end

function modules.services.object:_checkIfSpawnedObject(objectId)
    if self.objects[objectId] then -- if the object class exists skip the checks
        return
    end

    local object = modules.classes.object:create(objectId)

    if object:exists() then
        local objectData = server.getObjectData(objectId)
        if not objectData or objectData.object_type == 0 then
            return
        end
        self.objects[objectId] = object
        table.insert(self.spawnedObjectIndex, objectId)
        modules.libraries.logging:debug("services.object", "Detected spawned object with id: %s and type: %s", objectId, objectData.object_type)
        if self.onSpawnEvents[objectData.object_type] then
            modules.libraries.logging:debug("services.object", "Firing onSpawn event for object type: %s", objectData.object_type)
            self.onSpawnEvents[objectData.object_type]:fire(object, objectData)
        end
    end
end

function modules.services.object:connectOnSpawn(objectType, callback)
    modules.libraries.logging:info("services.object", "Connecting onSpawn event for object type: %s", objectType)
    if not self.onSpawnEvents[objectType] then
        self.onSpawnEvents[objectType] = modules.libraries.event:create()
    end

    self.onSpawnEvents[objectType]:connect(callback)
end

function modules.services.object:connectOnLoad(objectType, callback)
    if not self.onLoadEvents[objectType] then
        self.onLoadEvents[objectType] = modules.libraries.event:create()
    end

    self.onLoadEvents[objectType]:connect(callback)
end

function modules.services.object:connectOnUnload(objectType, callback)
    if not self.onUnloadEvents[objectType] then
        self.onUnloadEvents[objectType] = modules.libraries.event:create()
    end

    self.onUnloadEvents[objectType]:connect(callback)
end

function modules.services.object:_save()
    modules.libraries.gsave:saveService("object", self)
end

function modules.services.object:_load()
    local service = modules.libraries.gsave:loadService("object")
    if service.objects then
        for object_id,_ in pairs(service.objects) do
            self.objects[object_id] = modules.classes.object:create(object_id)
        end
    end
    if service._lastObjectId and service._lastObjectId ~= 0 then
        self._lastObjectId = math.floor(service._lastObjectId)
    end
end

function modules.services.object:_verifyObjectStates()
    for object_id, object in pairs(self.objects) do
        if not object:exists() then
            modules.libraries.logging:warning("services.object", "Object with id %s does not exist, removing from service.", object_id)
            self.objects[object_id] = nil
        end
    end
    self:_save()
end

function modules.services.object:_despawned(object)
    if self.objects[object.id] then
        self.objects[object.id] = nil
    end
    if self.spawnedObjectIndex[object.id] then
        self.spawnedObjectIndex[object.id] = nil
    end
    if self.loadedObjectIndex[object.id] then
        self.loadedObjectIndex[object.id] = nil
    end
end