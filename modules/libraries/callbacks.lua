modules.libraries.callbacks = {} -- table of callback functions

modules.libraries.callbacks.events = {} -- table of events

---@param name string the name of the callback you want to connect to
---@param callback function the function to be called when the event is fired
---@return EventConnection
---@overload fun(self, name: "onClearOilSpill", callback: fun())
---@overload fun(self, name: "onTick", callback: fun(game_ticks: number))
---@overload fun(self, name: "onCreate", callback: fun(is_world_create: boolean))
---@overload fun(self, name: "onDestroy", callback: fun())
---@overload fun(self, name: "onCustomCommand", callback: fun(full_message: string, peer_id: number, is_admin: boolean, is_auth: boolean, command: string, ...: string))
---@overload fun(self, name: "onChatMessage", callback: fun(peer_id: number, sender_name: string, message: string))
---@overload fun(self, name: "onPlayerJoin", callback: fun(steam_id: number, name: string, peer_id: number, is_admin: boolean, is_auth: boolean))
---@overload fun(self, name: "onPlayerSit", callback: fun(peer_id: number, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onPlayerUnsit", callback: fun(peer_id: number, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCharacterSit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCharacterUnsit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCharacterPickup", callback: fun(object_id_actor: integer, object_id_target: integer))
---@overload fun(self, name: "onCreatureSit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCreatureUnsit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCreaturePickup", callback: fun(object_id_actor: integer, object_id_target: integer))
---@overload fun(self, name: "onEquipmentPickup", callback: fun(character_object_id: integer, equipment_object_id: integer, equipment_id: SWEquipmentTypeEnum))
---@overload fun(self, name: "onEquipmentDrop", callback: fun(character_object_id: integer, equipment_object_id: integer, equipment_id: SWEquipmentTypeEnum))
---@overload fun(self, name: "onPlayerRespawn", callback: fun(peer_id: number))
---@overload fun(self, name: "onPlayerLeave", callback: fun(steam_id: number, name: string, peer_id: number, is_admin: boolean, is_auth: boolean))
---@overload fun(self, name: "onToggleMap", callback: fun(peer_id: number, is_open: boolean))
---@overload fun(self, name: "onPlayerDie", callback: fun(steam_id: number, name: string, peer_id: number, is_admin: boolean, is_auth: boolean))
---@overload fun(self, name: "onVehicleSpawn", callback: fun(vehicle_id: integer, peer_id: number, x: number, y: number, z: number, group_cost: number, group_id: integer))
---@overload fun(self, name: "onGroupSpawn", callback: fun(group_id: integer, peer_id: number, x: number, y: number, z: number, group_cost: number))
---@overload fun(self, name: "onVehicleDespawn", callback: fun(vehicle_id: integer, peer_id: number))
---@overload fun(self, name: "onVehicleLoad", callback: fun(vehicle_id: integer))
---@overload fun(self, name: "onVehicleUnload", callback: fun(vehicle_id: integer))
---@overload fun(self, name: "onVehicleTeleport", callback: fun(vehicle_id: integer, peer_id: number, x: number, y: number, z: number))
---@overload fun(self, name: "onObjectLoad", callback: fun(object_id: integer))
---@overload fun(self, name: "onObjectUnload", callback: fun(object_id: integer))
---@overload fun(self, name: "onButtonPress", callback: fun(vehicle_id: integer, peer_id: number, button_name: string, is_pressed: boolean))
---@overload fun(self, name: "onSpawnAddonComponent", callback: fun(vehicle_or_object_id: integer, component_name: string, type_string: string, addon_index: number))
---@overload fun(self, name: "onVehicleDamaged", callback: fun(vehicle_id: integer, damage_amount: number, voxel_x: number, voxel_y: number, voxel_z: number, body_index: integer))
---@overload fun(self, name: "httpReply", callback: fun(port: number, request: string, reply: string))
---@overload fun(self, name: "onFireExtinguished", callback: fun(fire_x: number, fire_y: number, fire_z: number))
---@overload fun(self, name: "onForestFireSpawned", callback: fun(fire_objective_id: number, fire_x: number, fire_y: number, fire_z: number))
---@overload fun(self, name: "onForestFireExtinguished", callback: fun(fire_objective_id: number, fire_x: number, fire_y: number, fire_z: number))
---@overload fun(self, name: "onTornado", callback: fun(transform: SWMatrix))
---@overload fun(self, name: "onMeteor", callback: fun(transform: SWMatrix, magnitude))
---@overload fun(self, name: "onTsunami", callback: fun(transform: SWMatrix, magnitude: number))
---@overload fun(self, name: "onWhirlpool", callback: fun(transform: SWMatrix, magnitude: number))
---@overload fun(self, name: "onVolcano", callback: fun(transform: SWMatrix))
---@overload fun(self, name: "onOilSpill", callback: fun(tile_x: number, tile_z: number, delta: number, total: number, vehicle_id: integer))
function modules.libraries.callbacks:connect(name, callback)
    local event = self:_initCallback(name) -- initialize the callback

    return event:connect(callback) -- connect the callback to the event
end

---@param name string the name of the callback you want to connect to
---@param callback function the function to be called when the event is fired
---@return EventConnection
---@overload fun(self, name: "onClearOilSpill", callback: fun())
---@overload fun(self, name: "onTick", callback: fun(game_ticks: number))
---@overload fun(self, name: "onCreate", callback: fun(is_world_create: boolean))
---@overload fun(self, name: "onDestroy", callback: fun())
---@overload fun(self, name: "onCustomCommand", callback: fun(full_message: string, peer_id: number, is_admin: boolean, is_auth: boolean, command: string, ...: string))
---@overload fun(self, name: "onChatMessage", callback: fun(peer_id: number, sender_name: string, message: string))
---@overload fun(self, name: "onPlayerJoin", callback: fun(steam_id: number, name: string, peer_id: number, is_admin: boolean, is_auth: boolean))
---@overload fun(self, name: "onPlayerSit", callback: fun(peer_id: number, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onPlayerUnsit", callback: fun(peer_id: number, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCharacterSit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCharacterUnsit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCharacterPickup", callback: fun(object_id_actor: integer, object_id_target: integer))
---@overload fun(self, name: "onCreatureSit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCreatureUnsit", callback: fun(object_id: integer, vehicle_id: integer, seat_name: string))
---@overload fun(self, name: "onCreaturePickup", callback: fun(object_id_actor: integer, object_id_target: integer))
---@overload fun(self, name: "onEquipmentPickup", callback: fun(character_object_id: integer, equipment_object_id: integer, equipment_id: SWEquipmentTypeEnum))
---@overload fun(self, name: "onEquipmentDrop", callback: fun(character_object_id: integer, equipment_object_id: integer, equipment_id: SWEquipmentTypeEnum))
---@overload fun(self, name: "onPlayerRespawn", callback: fun(peer_id: number))
---@overload fun(self, name: "onPlayerLeave", callback: fun(steam_id: number, name: string, peer_id: number, is_admin: boolean, is_auth: boolean))
---@overload fun(self, name: "onToggleMap", callback: fun(peer_id: number, is_open: boolean))
---@overload fun(self, name: "onPlayerDie", callback: fun(steam_id: number, name: string, peer_id: number, is_admin: boolean, is_auth: boolean))
---@overload fun(self, name: "onVehicleSpawn", callback: fun(vehicle_id: integer, peer_id: number, x: number, y: number, z: number, group_cost: number, group_id: integer))
---@overload fun(self, name: "onGroupSpawn", callback: fun(group_id: integer, peer_id: number, x: number, y: number, z: number, group_cost: number))
---@overload fun(self, name: "onVehicleDespawn", callback: fun(vehicle_id: integer, peer_id: number))
---@overload fun(self, name: "onVehicleLoad", callback: fun(vehicle_id: integer))
---@overload fun(self, name: "onVehicleUnload", callback: fun(vehicle_id: integer))
---@overload fun(self, name: "onVehicleTeleport", callback: fun(vehicle_id: integer, peer_id: number, x: number, y: number, z: number))
---@overload fun(self, name: "onObjectLoad", callback: fun(object_id: integer))
---@overload fun(self, name: "onObjectUnload", callback: fun(object_id: integer))
---@overload fun(self, name: "onButtonPress", callback: fun(vehicle_id: integer, peer_id: number, button_name: string, is_pressed: boolean))
---@overload fun(self, name: "onSpawnAddonComponent", callback: fun(vehicle_or_object_id: integer, component_name: string, type_string: string, addon_index: number))
---@overload fun(self, name: "onVehicleDamaged", callback: fun(vehicle_id: integer, damage_amount: number, voxel_x: number, voxel_y: number, voxel_z: number, body_index: integer))
---@overload fun(self, name: "httpReply", callback: fun(port: number, request: string, reply: string))
---@overload fun(self, name: "onFireExtinguished", callback: fun(fire_x: number, fire_y: number, fire_z: number))
---@overload fun(self, name: "onForestFireSpawned", callback: fun(fire_objective_id: number, fire_x: number, fire_y: number, fire_z: number))
---@overload fun(self, name: "onForestFireExtinguished", callback: fun(fire_objective_id: number, fire_x: number, fire_y: number, fire_z: number))
---@overload fun(self, name: "onTornado", callback: fun(transform: SWMatrix))
---@overload fun(self, name: "onMeteor", callback: fun(transform: SWMatrix, magnitude))
---@overload fun(self, name: "onTsunami", callback: fun(transform: SWMatrix, magnitude: number))
---@overload fun(self, name: "onWhirlpool", callback: fun(transform: SWMatrix, magnitude: number))
---@overload fun(self, name: "onVolcano", callback: fun(transform: SWMatrix))
---@overload fun(self, name: "onOilSpill", callback: fun(tile_x: number, tile_z: number, delta: number, total: number, vehicle_id: integer))
function modules.libraries.callbacks:once(name, callback)
    local event = self:_initCallback(name) -- initialize the callback

    return event:once(callback) -- connect the callback to the event
end

-- internal function to initialize a callback. do not call this directly.
---@param name string
---@return Event
function modules.libraries.callbacks:_initCallback(name)
    local event = self.events[name]

    if event then
        return event
    end

    if not event then
        event = modules.libraries.event:create() -- create a new event object
        self.events[name] = event -- add the event to the table
    end

    local existing = _ENV[name] -- check if the event already exists in the global environment

    if existing then
        _ENV[name] = function(...)
            existing(...)
            event:fire(...)
        end
    else
        _ENV[name] = function(...)
            event:fire(...)
        end
    end

    return event -- return the event
end