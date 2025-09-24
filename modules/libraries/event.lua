modules.libraries.event = {} -- table of event functions

-- create a new event object
---@return Event
function modules.libraries.event:create()
    return modules.classes.event:create() -- create a new event object 
end

modules.libraries.event.removeConnection = {}