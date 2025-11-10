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

function modules.services.task:create(period, func, repeating)
    local id = #self.tasks + 1
    local task = modules.classes.task:create(id, period, repeating, func)
    self.tasks[id] = task
    return task
end

function modules.services.task:_updateTask(task)
    self.tasks[task.id] = task
end