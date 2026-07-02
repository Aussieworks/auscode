auscode.classes.party = {}

---@param id number
function auscode.classes.party:create(id)
    ---@class ACParty
    local party = {
        _class = "ACParty",
        id = id,
        leader = "",
        members = {},
        invited = {},
    }

    ---@return Player|nil
    function party:getLeader()
        return modules.services.player:getPlayer(self.leader)
    end

    ---@param player Player
    function party:addMember(player)
        for _, steamId in pairs(self.members) do
            if steamId == player.steamId then
                return -- player is already a member
            end
        end
        table.insert(self.members, player.steamId)
        if #self.members == 1 then
            self.leader = player.steamId
        end
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
        if #self.members == 0 then
            self:delete()
        end
    end

    function party:setLeader(player)
        self.leader = player.steamId
    end

    function party:invite(player)
        table.insert(self.invited, player.steamId)
    end

    function party:removeInvite(player)
        for i, steamId in pairs(self.invited) do
            if steamId == player.steamId then
                table.remove(self.invited, i)
                break
            end
        end
    end

    function party:isInvited(player)
        for _, steamId in pairs(self.invited) do
            if steamId == player.steamId then
                return true
            end
        end
        return false
    end

    function party:save()
        auscode.player:saveParty(self)
    end

    function party:delete()
        auscode.player:deleteParty(self)
    end

    return party
end