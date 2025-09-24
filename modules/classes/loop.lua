modules.classes.loop = {} -- table of loop functions

---@return Loop
---@param time number
---@param func function
---@param id number
function modules.classes.loop:create(time, func, id)
    ---@class Loop
    local loop = {
        _class = "Loop",
        callback = func,
		time = time,
		creationTime = server.getTimeMillisec(),
		id = id,
		paused = false
    }

    -- set the loop into a paused state
    function loop:setPaused(state)
        self.paused = state
    end

    function loop:editTime(newtime)
        self.time = newtime
    end

    return loop
end