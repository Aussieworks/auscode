---@class taskService : Service
modules.services.task = modules.services:createService("task", "Service for creating and managing tasks", {"ChickenMst"})

function modules.services.task:initService()
   self.tasks = {} -- table of tasks 
end

function modules.services.task:startService()
    modules.libraries.callbacks:connect("onTick", function(game_ticks)
        for _, task in pairs(self.tasks) do
            task:tick()
        end
    end)
end

-- creates a new task
---@param period number time in seconds or ticks between each execution of the task
---@param func function the function to execute when the task runs
---@param repeating boolean whether the task should repeat
---@param useTime boolean whether to use time-based execution
function modules.services.task:create(period, func, repeating, useTime)
    local id = #self.tasks + 1
    local task = modules.classes.task:create(id, period, repeating, func, useTime)
    self.tasks[id] = task
    return task
end

function modules.services.task:_updateTask(task)
    self.tasks[task.id] = task
end