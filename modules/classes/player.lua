modules.classes.player = {} -- table of player functions

---@param peerId number
---@param steamId string|number
---@param name string|nil
---@param admin boolean|nil
---@param auth boolean|nil
---@param perms table|nil
---@param extra table|nil
---@param data table|nil
---@return Player
function modules.classes.player:create(peerId, steamId, name, admin, auth, objectId, perms, extra, data)
    ---@class Player
    local player = {
        _class = "Player",
        peerId = math.floor(peerId),
        steamId = tostring(steamId),
        name = name or "Unknown",
        admin = admin or false,
        auth = auth or false,
        objectId = objectId or nil,
        inGame = true,
        data = data or {},
        perms = perms or {},
        extra = extra or {}
    }

    -- sets the player classes name
    ---@param newName string
    function player:setName(newName)
        self.name = newName
    end

    -- sets the players admin
    ---@param isAdmin boolean
    function player:setAdmin(isAdmin)
        self.admin = isAdmin
        if isAdmin then
            server.addAdmin(self.peerId)
        else
            server.removeAdmin(self.peerId)
        end
    end

    -- sets the players auth
    ---@param isAuth boolean
    function player:setAuth(isAuth)
        self.auth = isAuth
        if isAuth then
            server.addAuth(self.peerId)
        else
            server.removeAuth(self.peerId)
        end
    end

    -- sets a specific extra value for the player
    ---@param key string|number
    ---@param value any
    function player:setExtra(key, value)
        if not self.extra then
            self.extra = {}
        end
        self.extra[key] = value
    end

    -- returns a specific extra value for the player
    ---@param key string|number
    ---@return any
    function player:getExtra(key)
        if not self.extra then
            return nil
        end
        return self.extra[key]
    end

    -- sets a permission for the player
    ---@param perm string
    ---@param value boolean|nil
    function player:setPerm(perm, value)
        self.perms[perm] = value
    end

    -- checks if the player has a specific permission
    ---@param perm string
    ---@param valueToMatch any|nil
    ---@return boolean
    function player:hasPerm(perm, valueToMatch)
        if not valueToMatch then
            return self.perms[perm] ~= nil
        end
        return self.perms[perm] == valueToMatch
    end

    -- returns the players permissions table
    ---@return table Player.perms
    function player:getPerms()
        return self.perms
    end

    -- removes a specific permission from the player
    ---@param perm string
    function player:removePerm(perm)
        if self.perms[perm] then
            self.perms[perm] = nil
        end
    end

    -- kicks the player from the server
    function player:kick()
        server.kickPlayer(self.peerId)
    end

    -- bans the player from the server
    function player:ban()
        server.banPlayer(self.peerId)
    end

    -- kills the players character
    function player:kill()
        local character = self.objectId or server.getPlayerCharacterID(self.peerId)
        server.killCharacter(character)
    end

    -- revives the players character
    function player:revive()
        local character = self.objectId or server.getPlayerCharacterID(self.peerId)
        server.reviveCharacter(character)
    end

    -- teleports the player to a specific position
    ---@param pos table
    function player:setPos(pos)
        server.setPlayerPos(self.peerId, pos)
    end

    -- returns the players position in the world
    ---@return table matrix
    ---@return boolean worked
    function player:getPos()
        local pos, worked = server.getPlayerPos(self.peerId)
        if not worked then
            return matrix.translation(0,0,0), false
        end
        return pos, worked
    end

    -- sets the player seated in a specific vehicle and seat
    function player:setSeated(vehcileId, seatName)
        return server.setCharacterSeated(self.objectId, vehcileId, seatName)
    end

    -- sends a notification to the player
    ---@param title string
    ---@param message string
    ---@param notificationType number
    function player:notify(title, message, notificationType)
        server.notify(self.peerId, title, message, notificationType)
    end

    -- gets the players data from the server, if update is true it will fetch new data from the server, otherwise it will return the cached data
    ---@param update boolean|nil
    ---@return table
    function player:getData(update)
        self.data = (update and server.getObjectData(self.objectId) or (self.data or server.getObjectData(self.objectId)))
        return self.data
    end

    -- sets the players hp
    ---@param hp number
    function player:setHp(hp)
        server.setCharacterData(self.objectId or server.getPlayerCharacterID(self.peerId), hp, false, false)
    end

    -- set an item in players inventory
    ---@param slot number
    ---@param item number
    ---@param bool boolean|nil
    ---@param int integer|nil
    ---@param float number|nil
    ---@return boolean success
    function player:setItem(slot, item, bool, int, float)
        return server.setCharacterItem(self.objectId, slot, item, bool or false, int, float)
    end

    ---@param slot number
    ---@return number id, boolean success
    function player:getItem(slot)
        return server.getCharacterItem(self.objectId, slot)
    end

    function player:save()
        modules.services.player:_updatePlayer(self)
    end

    return player
end