modules.classes.task = {}

function modules.classes.task:create(id, period, repeating, func)
    ---@class Task
    ---@field id number
    ---@field period number
    ---@field repeating boolean
    ---@field paused boolean
    ---@field counter number
    ---@field func fun(task: Task)
    local task = {
        _class = "Task",
        id = id,
        period = period,
        repeating = repeating,
        paused = false,
        counter = 0,
        func = func,
    }

    function task:setPaused(paused)
        self.paused = paused
    end

    function task:setPeriod(period)
        self.period = period
    end

    function task:setRepeating(repeating)
        self.repeating = repeating
    end

    function task:resetCounter()
        self.counter = 0
    end

    function task:tick()
        if self.paused then
            return
        end

        self.counter = self.counter + 1
        if self.counter >= self.period then
            self:resetCounter()
            self:func()
            if not self.repeating then
                self:setPaused(true)
            end
        end
    end

    function task:update()
        modules.services.task:_updateTask(self)
    end

    return task
end