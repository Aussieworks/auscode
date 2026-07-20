modules.libraries.chat = {} -- table of chat functions

modules.libraries.chat.messages = {}

modules.libraries.chat.onAnnounce = modules.libraries.event:create()

---@param title string
---@param message string
---@param target number|nil either nil, the target player ID, or -1 for all players
function modules.libraries.chat:announce(title, message, target, log)
    target = target or -1 -- set the target to all if not specified
    server.announce(title, message, target) -- send the message to the server
    if log ~= false then
        table.insert(self.messages, {title = title, message = message, target = target}) -- add the message to the messages table
        self.onAnnounce:fire({title = title, message = message, target = target}) -- add the message to the messages table
        self:_checkMessagesTable() -- check if the messages table is over the limit and remove the oldest message if it is
    end
end

---@param title string
---@param message string
---@param log boolean|nil whether to log the message or not, defaults to true
---@param ... number|table the target player IDs to send the announcement to
function modules.libraries.chat:announceGroup(title, message, log, ...) -- send an announcement to a group of players
    local targets = table.pack(...)
    if type(targets[1]) == "table" then -- if a table has been passed in set targets to that table
        targets = targets[1]
    end
    for _, target in pairs(targets) do
        server.announce(title, message, target) -- announce to each individual player
    end

    if log ~= false then
        table.insert(self.messages, {title = title, message = message, target = targets}) -- add the message to the messages table
        self.onAnnounce:fire({title = title, message = message, target = targets}) -- add the message to the messages table
        self:_checkMessagesTable() -- check if the messages table is over the limit and remove the oldest message if it is
    end
end

function modules.libraries.chat:_checkMessagesTable()
    while modules.libraries.table:count(self.messages) > 1000 do
        table.remove(self.messages, 1) -- remove the oldest message if the limit is exceeded
    end
end