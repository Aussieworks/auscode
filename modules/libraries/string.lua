modules.libraries.string = {} -- table of string functions

-- calculates the Damerau Levenshtein Distance (lower means more similar)
---@param a string
---@param b string
---@return number distance
function modules.libraries.string:DlDistance(a,b)
    local da = {}
    for i = 1, 256 do
        da[i] = 0
    end

    local d = {}
    for i = -1, #a do
        for j = -1, #b do
            d[i] = d[i] or {}
            d[i][j] = 0
        end
    end

    local maxdist = #a + #b
    d[-1][-1] = maxdist
    for i = 0, #a do
        d[i][-1] = maxdist
        d[i][0] = i
    end
    for j = 0, #b do
        d[-1][j] = maxdist
        d[0][j] = j
    end
    for i = 1, #a do
        local db = 0
        for j = 1, #b do
            local k = da[b:byte(j,j)]
            local e = db
            local cost = 1
            if a:byte(i,i) == b:byte(j,j) then
                cost = 0
                db = j
            end
            d[i][j] = math.min(d[i-1][j-1] + cost, d[i][j-1] + 1, d[i-1][j] + 1, d[k-1][e-1] + (i-k-1) + cost + (j-e-1))
        end
        da[a:byte(i,i)] = i
    end
    return d[#a][#b]
end