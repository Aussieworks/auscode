---@class HttpService: Service
---@field requests table<number, HttpRequest>
---@field groupedRequests table<number>
---@field counter number
---@field backendPort number
modules.services.http = modules.services:createService("http", "Service for handling HTTP requests", {"ChickenMst"})

function modules.services.http:initService()
    self.requests = {} -- table to store HTTP requests
    self.groupedRequests = {} -- table to store grouped requests
    self.counter = 0 -- counter for request IDs
    self.backendPort = modules.libraries.settings:getValue("backendPort",true, 8080) -- default backend port

    if modules.addonReason == "reload" then
        self:_load()
    elseif modules.addonReason == "load" then
        self:_load(true)
    end
end

function modules.services.http:startService()
    modules.libraries.callbacks:connect("httpReply", function(port, request, reply)
        if port == 0 then
            return
        end
        local requestId = self:_deformatToId(request)
        if requestId == nil then
            local grouped = self:_deformatGrouped(request)
            if type(modules.libraries.json:decode(reply)) == "table" then
                reply = modules.libraries.json:decode(reply)
            end

            if grouped then
                for _, requested in pairs(grouped) do
                    if self.requests[requested.id] then
                        modules.libraries.logging:debug("httpReply()", "Received reply for grouped request ID: " .. tostring(requested.id))
                        if type(reply) == "table" then
                            for _, v in pairs(reply) do -- find the matching request ID in the grouped reply
                                if v.id == requested.id then
                                    self.requests[requested.id]:func(v) -- call the callback function with the reply
                                end
                            end
                        else
                            self.requests[requested.id]:func(reply) -- call the callback function with the reply
                        end
                    else
                        modules.libraries.logging:warning("httpReply()", "Grouped request ID: " .. tostring(requested.id) .. " not found in requests table")
                    end
                end
            end
        else
            modules.libraries.logging:debug("httpReply()", "Received reply for request ID: " .. tostring(requestId) .. ": " .. reply)
            self.requests[requestId]:func(reply) -- call the callback function with the reply
        end
        self:_save() -- save the service state after receiving a reply
    end)

    modules.libraries.callbacks:connect("onTick", function(game_ticks)
        if #self.groupedRequests ~= 0 then
            local group = self.groupedRequests

            local formatedRequest = self:_formatGrouped(group)

            if formatedRequest then
                server.httpGet(self.backendPort, formatedRequest) -- send the grouped request

                modules.libraries.logging:debug("http:onTick()", "Sent grouped request: "..formatedRequest)
            end

            self.groupedRequests = {} -- clear the grouped requests after sending
        end
    end)
end

-- send a http or grouped http request through the backend
---@param port number
---@param url string
---@param callback function
---@param groupedRequest boolean
---@return HttpRequest|nil
function modules.services.http:get(port, url, callback, groupedRequest)
    -- Increment the counter for a new request ID
    self.counter = self.counter + 1
    local requestId = self.counter

    -- Store the request and its callback
    self.requests[requestId] = modules.classes.httpRequest:create(url, port, requestId, callback)

    if groupedRequest then
        table.insert(self.groupedRequests, requestId)

        modules.libraries.logging:debug("http:get()", "Request with ID: " .. tostring(requestId) .. " has been saved to be sent as a grouped request")
    else
        local formatedRequest = self:_format(self.requests[requestId])

        -- Send the HTTP request
        server.httpGet(port, formatedRequest)

        modules.libraries.logging:debug("http:get()", "Sent request with ID: " .. tostring(requestId) .. " to port: " .. tostring(port) .. " with URL: " .. url .. " formated to: "..formatedRequest)

        return self.requests[requestId]
    end
    self:_save() -- save the service state after adding a new request
end

-- internal function to format the request for sending
---@param request HttpRequest
---@return string
function modules.services.http:_format(request)
    -- Format the request for sending
    local striped = modules.libraries.table:strip(request, "function")
    local jsonRequest = modules.libraries.json:encode(striped)
    modules.libraries.logging:debug("http:_format()", "Formatted request: " .. jsonRequest)
    return "/api/http/get?request="..jsonRequest
end

-- internal function to format grouped requests for sending
---@param requestIds table<number>
---@return string|nil
function modules.services.http:_formatGrouped(requestIds)
    local requests = {}
    for _, requestId in pairs(requestIds) do
        local request = self.requests[requestId]
        if request then
            local stripedRequest = modules.libraries.table:strip(request, "function")

            if stripedRequest._class then
                stripedRequest._class = nil
            end

            table.insert(requests, stripedRequest)
            modules.libraries.logging:debug("http:_formatGrouped()", "Grouped request ID: " .. tostring(requestId) .. " preped for sending")
        else
            modules.libraries.logging:warning("http:_formatGrouped()", "Request ID: " .. tostring(requestId) .. " not found in requests table")
        end
    end

    if #requests > 0 then
        local formatedRequest = modules.libraries.json:encode(requests)
        return "/api/http/group?request=" .. formatedRequest
    end
end

-- internal function to deformat the request ID from the formatted request string
---@param formatedRequest string
---@return number|nil
function modules.services.http:_deformatToId(formatedRequest)
    local request = string.gsub(formatedRequest, "/api/http/get%?request=", "")
    modules.libraries.logging:debug("http:_deformatToId()", "Deformatted request: " .. request)
    request = modules.libraries.json:decode(request)
    return request and request.id or nil
end

-- internal function to deformat grouped requests from the formatted request string
---@param groupedRequest string
---@return table|nil
function modules.services.http:_deformatGrouped(groupedRequest)
    local request = string.gsub(groupedRequest, "/api/http/group%?request=", "")
    modules.libraries.logging:debug("http:_deformatGrouped()", "Deformatted grouped request: " .. request)
    request = modules.libraries.json:decode(request)
    if type(request) == "table" then
        return request
    end
end

-- internal function to save the HTTP service to gsave
function modules.services.http:_save()
    modules.libraries.gsave:saveService("http", self)
end

-- internal function to load the HTTP service form gsave
---@param load boolean|nil
function modules.services.http:_load(load)
    local loaded = modules.libraries.gsave:loadService("http")
    if loaded and not load then
        if loaded.requests == nil then
            modules.libraries.logging:warning("http:_load()", "No requests found in saved HTTP service")
            loaded.requests = {}
        else
            for id, request in pairs(loaded.requests) do
                if type(request) == "table" then
                    self.requests[id] = modules.classes.httpRequest:create(request.url, request.port, id, function(request, reply)
                        modules.libraries.logging:error("httpRequest", "Http reply received after reload or load, function no longer exists for ID: " .. tostring(id))
                    end)
                else
                    modules.libraries.logging:warning("http:_load()", "Invalid request format for ID: " .. tostring(id))
                end
            end
        end
        self.counter = math.floor((loaded and loaded.counter or self.counter))
        modules.libraries.logging:debug("http:_load()", "HTTP service loaded with " .. #self.requests .. " requests")
    elseif loaded and load then
        self.counter = math.floor((loaded and loaded.counter or self.counter))
    end
end