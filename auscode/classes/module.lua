auscode.classes.module = {}

function auscode.classes.module:create(name, authors, description, version)
    ---@class ACModule
    ---@field _class string
    ---@field name string
    ---@field version string
    ---@field authors table<string>
    ---@field description string
    ---@field isInitialized boolean
    ---@field hasStarted boolean
    ---@field restart function
    ---@field _init function
    ---@field _start function
    ---@field _cleanup function
    local module = {
        _class = "ACModule",
        name = name or "unnamedModule",
        version = version or "unknown",
        authors = authors or {"UnknownAuthor"},
        description = description or "No description provided.",
        isInitialized = false,
        hasStarted = false,
        isRestarting = false,
    }

    function module:init(safeMode)
        if self.isInitialized then
            modules.libraries.logging:warning("module:_init()", "Module '"..self.name.."' has already been initialized. Aborting redundant init call.")
            return
        end

        safeMode = safeMode or false

        self:_init(safeMode)
        self.isInitialized = true
        return self.isInitialized
    end

    function module:start(safeMode)
        if self.hasStarted then
            modules.libraries.logging:warning("module:_start()", "Module '"..self.name.."' has already started. Aborting redundant start call.")
            return
        end

        safeMode = safeMode or false

        self:_start(safeMode)
        self.hasStarted = true
    end

    function module:restart(safeMode)
        safeMode = safeMode or false
        if self.isRestarting then
            modules.libraries.logging:warning("module:_restart()", "Module '"..self.name.."' is already restarting. Aborting redundant restart call.")
            return
        end

        self.isRestarting = true

        if self.hasStarted then
            self:_cleanup()
            self.hasStarted = false
        end

        self.isInitialized = false

        local worked = self:init(safeMode) and self:start(safeMode)
        self.isRestarting = false

        return worked
    end

    function module:_init()
        modules.libraries.logging:warning("module:_init()", "Module '"..self.name.."' has no _init() function defined. Defaulting to successful init.")
        return true
    end

    function module:_start()
        modules.libraries.logging:warning("module:_start()", "Module '"..self.name.."' has no _start() function defined. Defaulting to successful start.")
        return true
    end

    function module:_cleanup()
        modules.libraries.logging:warning("module:_cleanup()", "Module '"..self.name.."' has no _cleanup() function defined. Defaulting to no cleanup.")
        return true
    end

    return module
end