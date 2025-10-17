modules.classes.widgets.color = {}

---@return Color
function modules.classes.widgets.color:create(r, g, b, a)
    ---@class Color
    ---@field r integer
    ---@field g integer
    ---@field b integer
    ---@field a integer
    local color = {
        _class = "Color",
        r = r or 255,
        g = g or 255,
        b = b or 255,
        a = a or 255,
    }

    return color
end