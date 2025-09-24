modules.classes.httpRequest = {}

---@param request string
---@param port number
---@param id number
---@param func fun(request:HttpRequest, reply: any) | nil
---@return HttpRequest
function modules.classes.httpRequest:create(request, port, id, func)
    ---@class HttpRequest
    local httpRequest = {
        _class = "HttpRequest",
        request = request, -- the request object
        port = port, -- the port the request was made on
        id = math.floor(id) or 0, -- unique ID for the request
        func = func -- function to call when the request is complete
    }

    return httpRequest
end