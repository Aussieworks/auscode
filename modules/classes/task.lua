modules.classes.task = {}

function modules.classes.task:create(id, period, repeating, func, useTime)
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
        period = useTime and period*1000 or period,
        repeating = repeating,
        paused = false,
        counter = 0,
        start = modules.services.tps._last,
        func = func,
        useTime = useTime
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
        if self.useTime then self.start = modules.services.tps._last end
    end

    function task:tick()
        if self.paused then
            return
        end

        self.counter = self.useTime and modules.services.tps._last-self.start or self.counter + 1

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