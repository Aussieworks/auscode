modules.classes.service = {}

---@param name string
---@param description string
---@param authors table<string>
---@return Service
function modules.classes.service:create(name, description, authors)
    ---@class Service
    ---@field initService function
    ---@field startService function
    local service = {
        _class = "Service",
        name = name,
        description = description,
        authors = authors,

        hasInit = false,
        hasStarted = false
    }

    -- initializes the service, runs the init function of the service
    function service:_init()
        if self.hasInit then
            modules.libraries.logging:warning("service:_init()", "Service '%s' is already initialized.", self.name)
            return
        end

        modules.libraries.logging:debug("service:_init()", "Initializing service '%s'", self.name)
        self.hasInit = true

        if not self.initService then
            return
        end

        self:initService()
    end

    -- starts the service, runs the start function of the service
    function service:_start()
        if self.hasStarted then
            modules.libraries.logging:warning("service:_start()", "Attempted to start service '%s' that is already started.", self.name)
            return
        end

        if not self.hasInit then
            modules.libraries.logging:error("service:_start()", "Attempted to start service '%s' that is not initialized.", self.name)
            return
        end

        modules.libraries.logging:debug("service:_start()", "Starting service '%s'", self.name)
        self.hasStarted = true

        if not self.startService then
            return
        end

        self:startService()
    end

    return service
end