local O = require("lib.Object")
local util = require("lib.util")

-- 注意，谓词不应该修改参数
---@class a546.Filter
---@field predicate fun(resource:a546.Resource):boolean,number?
---@field name string
local Filter = O:extend()

---@cast Filter +fun(predicate:(fun(resource:a546.Resource):boolean,number?),name?:string):a546.Filter
function Filter:new(predicate, name)
    self.predicate = predicate or function()
        return true
    end
    self.name = name or util.generateRandomString(4)
end

function Filter:__tostring()
    return self.name
end

--- AND
---@param filter a546.Filter
---@return a546.Filter
function Filter:And(filter)
    return Filter(function(resource)
        local take1, howMuch1 = self.predicate(resource)
        local take2, howMuch2 = filter.predicate(resource)
        ---@type number|nil
        local howMuch
        if howMuch1 and howMuch2 then
            howMuch = math.min(howMuch1, howMuch2)
        end
        return take1 and take2, howMuch
    end)
end

--- OR
---@param filter a546.Filter
---@return a546.Filter
function Filter:Or(filter)
    return Filter(function(resource)
        local take1, howMuch1 = self.predicate(resource)
        local take2, howMuch2 = filter.predicate(resource)
        ---@type number|nil
        local howMuch
        if howMuch1 and howMuch2 then
            howMuch = math.max(howMuch1, howMuch2)
        end
        return take1 or take2, howMuch
    end)
end

--- NOT
---@return a546.Filter
function Filter:Not()
    return Filter(function(resource)
        return not self.predicate(resource)
    end)
end

return Filter
