---@class playerService: Service
---@field players table<string, Player> -- table of players
modules.services.player = modules.services:createService("player", "Handles player data and events", {"ChickenMst"})

function modules.services.player:initService()
    self.onJoin = modules.libraries.event:create()
    self.onLeave = modules.libraries.event:create()
    self.onLoad = modules.libraries.event:create() -- doesnt work in singleplayer

    self.players = {}
    self.peerIdIndex = {} -- used to convert peerId to steamId
end


function modules.services.player:startService()
    if modules.addonReason ~= "create" then
        self:_load() -- load the player service on creationTime
    end

    modules.libraries.callbacks:connect("onPlayerJoin", function(steam_id, name, peer_id, is_admin, is_auth)
        name = self:_cleanName(name)
        modules.libraries.logging:debug("onPlayerJoin", "Player joined with steam_id: " .. steam_id .. ", name: " .. name .. ", peer_id: " .. peer_id)
        local player = self:getPlayer(tostring(steam_id))

        if not player then
            player = modules.classes.player:create(peer_id, steam_id, name, is_admin, is_auth)
            if not player then
                modules.libraries.logging:warning("services.player", "Failed to create player class: " .. steam_id)
                return
            end
        end

        player.inGame = true -- set the player as in-game
        player.peerId = peer_id -- update the peer_id
        self.players[tostring(steam_id)] = player -- add the player to the table
        self.peerIdIndex[tostring(peer_id)] = tostring(steam_id) -- map peerId to steamId
        self:_save() -- save the player service
        self.onJoin:fire(player) -- fire the event
    end)

    modules.libraries.callbacks:connect("onPlayerLeave", function(steam_id, name, peer_id, is_admin, is_auth)
        -- skip if steam_id is nil or 0
        if not steam_id or steam_id == 0 then
            return
        end

        name = self:_cleanName(name)

        modules.libraries.logging:debug("onPlayerLeave", "Player left with steam_id: " .. (steam_id or "unknown") .. ", name: " .. name .. ", peer_id: " .. peer_id)
        local player = self:getPlayer(tostring(steam_id))

        if player then
            player.inGame = false -- set the player as not in-game
            self.onLeave:fire(player) -- fire the event
            self.players[tostring(steam_id)] = player
            self:_save() -- save the player service
        end
    end)

    modules.libraries.callbacks:connect("onObjectLoad", function(object_id)
        local players = self:getOnlinePlayers()

        for _, player in pairs(players) do
            local playerObjId = server.getPlayerCharacterID(player.peerId)
            if playerObjId == object_id then
                modules.libraries.logging:debug("onObjectLoad", "Player loaded with steam_id: " .. player.steamId .. ", name: " .. player.name .. ", peer_id: " .. player.peerId)
                self.onLoad:fire(player) -- fire the event
            end
        end
    end)
end

-- get a player by their steam_id
---@param steam_id string
---@return Player|nil
function modules.services.player:getPlayer(steam_id)
    if self.players[tostring(steam_id)] then
        modules.libraries.logging:debug("services.player:getPlayer", "Found player with steam_id: " .. steam_id)
        return self.players[tostring(steam_id)] -- return the player object if found
    end
    modules.libraries.logging:info("services.player:getPlayer", "Player not found with steam_id: " .. steam_id)
end

-- get a player by their peer_id
---@param peer_id number
---@return Player|nil
function modules.services.player:getPlayerByPeer(peer_id)
    if self.peerIdIndex[tostring(peer_id)] ~= nil then
        modules.libraries.logging:debug("services.player:getPlayerByPeer", "Found steam_id: " .. self.peerIdIndex[tostring(peer_id)] .. " from peer_id: " .. tostring(peer_id))
        local player = self:getPlayer(self.peerIdIndex[tostring(peer_id)])
        if player then
            modules.libraries.logging:debug("services.player:getPlayerByPeer", "Found player: " .. player.name .. " from peer_id: " .. player.peerId)
            return player -- return the player object if found
        end
    end
end

-- get all players
---@return table<string, Player>
function modules.services.player:getPlayers()
    return self.players -- return the list of players
end

-- get all online players
---@return table<string, Player>
function modules.services.player:getOnlinePlayers() -- returns a table of players that are currently in-game
    local onlinePlayers = {}
    for _, player in pairs(self:getPlayers()) do
        if player.inGame then
            onlinePlayers[tostring(player.steamId)] = player -- add the player to the table if they are in-game
        end
    end
    return onlinePlayers -- return the list of online players
end

-- check if two players are the same
---@param player1 Player
---@param player2 Player
---@return boolean
function modules.services.player:isSamePlayer(player1, player2)
    if not player1 or not player2 then
        return false -- return false if either player is nil
    end
    return player1.steamId == player2.steamId -- compare the steam_ids of the players
end

-- internal function to load the players from gsave
function modules.services.player:_load()
    local service = modules.libraries.gsave:loadService("player")

    if service.players ~= nil then
        for _, playerData in pairs(service.players) do
            if not playerData or not playerData.steamId then
                modules.libraries.logging:warning("services.player:_load", "Skiped loading player data, no data")
                goto continue -- skip if playerData is nil or steamId is missing
            end
            if playerData.steamId == "0" then
                modules.libraries.logging:debug("services.player:_load", "Skiped loading player: "..playerData.name)
                goto continue -- skip players with steam_id 0
            end
            local player = modules.classes.player:create(
                playerData.peerId,
                playerData.steamId,
                playerData.name,
                playerData.admin,
                playerData.auth,
                playerData.perms,
                playerData.extra
            )
            if not player then
                modules.libraries.logging:warning("services.player:_load", "Failed to create player class for steam_id: " .. playerData.steam_id)
            else
                self.players[tostring(playerData.steamId)] = player -- add the player to the table
                modules.libraries.logging:debug("services.player:_load", "Loaded player: " .. player.name .. " with steam_id: " .. player.steamId)
            end
            ::continue::
        end
    end

    self:_verifyOnlinePlayers() -- verify online players after loading

    for _, player in pairs(server.getPlayers()) do
        if player.steam_id == 0 then
            modules.libraries.logging:debug("services.player:_load", "Skiped loading player: "..player.name)
            goto continue -- skip players with steam_id 0
        end
        local existingPlayer = self:getPlayer(tostring(player.steam_id))
        if not existingPlayer then
            local newPlayer = modules.classes.player:create(
                player.id,
                player.steam_id,
                player.name,
                player.admin,
                player.auth
            )
            if newPlayer then
                self.players[tostring(player.steam_id)] = newPlayer -- add the player to the table
                modules.libraries.logging:debug("services.player:_load", "Created player class for player: " .. newPlayer.name .. " with steam_id: " .. newPlayer.steamId)
                modules.services.player:_save() -- save the player service
            else
                modules.libraries.logging:warning("services.player:_load", "Failed to create player class for steam_id: " .. player.steam_id)
            end
        end
        ::continue::
    end
    modules.services.player:_save() -- save the player service after loading
end

-- internal function to save the players to gsave
function modules.services.player:_save()
    modules.libraries.gsave:saveService("player", self)
end

-- internal function to verify if the players are online
function modules.services.player:_verifyOnlinePlayers()
    local onlinePlayers = {}

    for _, player in pairs(server.getPlayers()) do
        onlinePlayers[tostring(player.steam_id)] = true -- mark the player as online
        self.peerIdIndex[tostring(player.id)] = tostring(player.steam_id) -- map peerId to steamId
    end

    for _, player in pairs(self.players) do
        player.inGame = onlinePlayers[tostring(player.steamId)] ~= nil -- set inGame based on onlinePlayers
        if not player.inGame and modules.addonReason == "load" then
            player.peerId = -1
        end
    end
end

-- internal function to clean the player name of any characters that break chat
function modules.services.player:_cleanName(name)
    return string.gsub(name, "[<]", "")
end