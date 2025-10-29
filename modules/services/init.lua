-- init serveices
modules.services = {}
modules.services.created = {} -- table of created services
modules.services.ordered = {}

-- create a new service with the inputed name, description and authors
---@param name string
---@param description string
---@param authors table<string>
---@return Service
function modules.services:createService(name, description, authors)
    self.ordered[#self.ordered + 1] = name -- add the service name to the ordered list
    if self.created[name] then
        modules.libraries.logging:error("services:create()", "Attempted to create service '%s' that already exists.",  name)
    end

    local service = modules.classes.service:create(name, description or "N/A", authors or {}) -- create a new service

    self.created[name] = service -- add the service to the created services table

    return service -- return the created service
end

-- get the service with the inputed name
---@param name string
---@return Service
function modules.services:getService(name)
    local service = self.created[name] -- get the service by name

    if not service then
        modules.libraries.logging:error("services:getService()", "Attempted to get service '%s' that does not exist.", name)
    end

    if not service.hasInit then
        modules.libraries.logging:warning("services:getService()", "Attempted to get service '%s' that is not initialized.", name)
    end

    return service -- return the service
end

-- internal function to initialize all services
function modules.services:_initServices()
    for _, name in pairs(self.ordered) do
        self.created[name]:_init()
    end
end

-- internal function to start all services
function modules.services:_startServices()
    for _, name in pairs(self.ordered) do
        self.created[name]:_start()
    end
end

require "modules.services.http" -- load the HTTP service
require "modules.services.addon" -- load the addons service
require "modules.services.player" -- load the player service
require "modules.services.loop" -- load the loops service
require "modules.services.command" -- load the commands service
require "modules.services.tps" -- load the TPS service
require "modules.services.vehicle" -- load the vehicles service
require "modules.services.ui" -- load the UI service