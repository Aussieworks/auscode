modules.classes.httpRequest = {}

---@param url string
---@param id number
---@param func fun(request:HttpRequest, reply: any) | nil
---@return HttpRequest
function modules.classes.httpRequest:create(url, id, func)
    ---@class HttpRequest
    local httpRequest = {
        _class = "HttpRequest",
        url = url, -- the request object
        id = math.floor(id) or 0, -- unique ID for the request
        func = func -- function to call when the request is complete
    }

    return httpRequest
end