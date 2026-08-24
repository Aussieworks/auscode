modules.classes.object = {}

function modules.classes.object:create(id)
    ---@class Object
    local object = {
        _class = "Object",
        id = id
    }

    function object:despawn()
        server.despawnObject(self.id, true)
        modules.services.object:_despawned(self)
    end

    function object:isLoaded()
        local sim, worked = server.getObjectSimulating(self.id)
        return sim and worked
    end

    function object:exists()
        local _, exists = server.getObjectSimulating(self.id)
        return exists
    end

    return object
end