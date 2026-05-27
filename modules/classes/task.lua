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

    -- sets the tasks paused state, if paused is true the task will not run, if false it will run
    ---@param paused boolean
    function task:setPaused(paused)
        self.paused = paused
    end

    -- sets the tasks period, this is the time in seconds or ticks between each execution of the task
    ---@param period number
    function task:setPeriod(period)
        self.period = period
    end

    -- sets the tasks repeating state, if repeating is true the task will repeat after each execution, if false it will only run once
    ---@param repeating boolean
    function task:setRepeating(repeating)
        self.repeating = repeating
    end

    -- resets the tasks counter
    function task:resetCounter()
        self.counter = 0
        if self.useTime then self.start = modules.services.tps._last end
    end

    -- called every tick by the task service to update the task
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

    if not task.useTime and task.period == 1 then
        function task:tick()
            if self.paused then
                return
            end

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