auscode.classes.party = {}

---@param leader string|nil
function auscode.classes.party:create(id, leader)
    ---@class ACParty
    local party = {
        _class = "ACParty",
        id = id,
        leader = leader,
        members = {},
    }

    ---@return Player|nil
    function party:getLeader()
        return modules.services.player:getPlayer(self.leader)
    end

    ---@param player Player
    function party:addMember(player)
        table.insert(self.members, player.steamId)
    end

    ---@param player Player
    function party:removeMember(player)
        if self.members[player.steamId] then
            for i, steamId in pairs(self.members) do
                if steamId == player.steamId then
                    table.remove(self.members, i)
                    break
                end
            end

            if self.leader == player.steamId then
                self.leader = self.members[1] -- set the new leader to the first member in the list
            end
        end
    end

    function party:setLeader(player)
        self.leader = player.steamId
    end

    function party:save()
        auscode.player:saveParty(self)
    end

    return party
end