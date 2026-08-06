modules.classes.polygon = {}


---@param ... SWMatrix
function modules.classes.polygon:create(...)
    ---@class Polygon
    ---@field points SWMatrix[]
    local polygon = {
        points = {...},
        lines = {},
    }

    function polygon:makeLines()
        for i,m in pairs(self.points) do
            local nextIndex = i + 1
            if nextIndex > #self.points then
                nextIndex = 1
            end

            local m2 = self.points[nextIndex]
            table.insert(self.lines, {m, m2})
        end
    end

    return polygon
end