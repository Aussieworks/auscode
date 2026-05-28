---@class ACChat : ACModule
auscode.chat = auscode.classes.module:create("chat", {"ChickenMst"}, "Handles custom chat functionality and chat logging.")

function auscode.chat:_init()
    self.messages = modules.libraries.gsave:loadTable("chatMessages") or {} -- load chat messages from g_savedata
    for _, message in pairs(modules.libraries.chat.messages) do
        table.insert(self.messages, message) -- add the messages from the chat library before auscode starts
    end
    self.chatMaxMessages = modules.libraries.settings:getValue("auscodeChatMessageLimit", true, 100) -- maximum number of chat messages to store
    while count(self.messages) < self.chatMaxMessages do
        table.insert(self.messages, {title = "", message = "", target = -1})
    end
    self.chatCustomChat = modules.libraries.settings:getValue("auscodeChatCustomChat", true, true) -- if custom chat functionality should be enabled
    self.hiddenWords = modules.libraries.settings:getValue("auscodeChatHiddenWords", true, {}) -- list of words to hide in chat messages eg {"badword1", "badword2"}
    self.hiddenWordReplacement = modules.libraries.settings:getValue("auscodeChatHiddenWordReplacement", true, "*") -- character to replace hidden words with
    return true
end

function auscode.chat:_start()
    self.onChatMessageConnection = modules.libraries.callbacks:connect("onChatMessage", function (peer_id, sender_name, message)
        local player = modules.services.player:getPlayerByPeer(peer_id)
        if player then
            local tag = auscode.player:getPermTag(auscode.player:getHighestPerm(player))
            local name = string.format("%s %s", tag, player.name)
            message = self:replaceHiddenWords(message, self.hiddenWordReplacement) -- replace hidden words with the specified replacement
            table.insert(self.messages, {title = name, message = message, target = -1}) -- add the message to the messages table
            while count(self.messages) > self.chatMaxMessages do
                table.remove(self.messages, 1) -- remove the oldest message if the limit is exceeded
            end
            modules.libraries.gsave:saveTable("chatMessages", self.messages) -- save the messages table to g_savedata
            if self.chatCustomChat then
                self:send()
            end
        end
    end)

    self.onAnnounceConnection = modules.libraries.chat.onAnnounce:connect(function(log)
        table.insert(self.messages, log) -- add the message to the messages table
        while count(self.messages) > self.chatMaxMessages do
            table.remove(self.messages, 1) -- remove the oldest message if the limit is exceeded
        end
        modules.libraries.gsave:saveTable("chatMessages", self.messages) -- save the messages table to g_savedata
    end)

    self.sendChatTask = modules.services.task:create(1,function()
        self:_send()
    end, false, false) -- create a task to send chat messages every second, but don't start it yet

    if not self.chatCustomChat then
        self.sendChatTask:setPaused(true) -- pause the task until we have messages to send
        self.sendChatTask:update() -- update the task to set the initial time
    end

    return true
end

function auscode.chat:_cleanup()
    self.onChatMessageConnection:disconnect()
    self.onAnnounceConnection:disconnect()
    return true
end

function auscode.chat:send()
    self.sendChatTask:setPaused(false) -- unpause the task to start sending messages
    self.sendChatTask:resetCounter() -- reset the task counter to send immediately
    self.sendChatTask:update()
end

function auscode.chat:_send()
    local messages = self.messages
    for _, message in pairs(messages) do
        if type(message.target) == "table" then
            modules.libraries.chat:announceGroup(message.title, message.message, message.target)
        else
            modules.libraries.chat:announce(message.title, message.message, message.target, false)
        end
    end
end

function auscode.chat:replaceHiddenWords(message, replacement)
    for _, word in pairs(self.hiddenWords) do
        for i=1, #word do
            local startIndex, endIndex = string.find(message:lower(), word:lower(), i, true)
            if startIndex then
                message = message:sub(1, startIndex - 1) .. replacement:rep(endIndex - startIndex + 1) .. message:sub(endIndex + 1)
                i = endIndex + 1
            else
                break
            end
        end
    end
    return message
end