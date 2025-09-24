modules.libraries.chat = {} -- table of chat functions

modules.libraries.chat.messages = {} -- table of chat messages

---@param title string
---@param message string
---@param target number|nil either nil, the target player ID, or -1 for all players
function modules.libraries.chat:announce(title, message, target)
    target = target or -1 -- set the target to all if not specified
    server.announce(title, message, target) -- send the message to the server
    table.insert(self.messages, {title = title, message = message, target = target}) -- add the message to the messages table
end