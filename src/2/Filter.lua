local O = require("lib.Object")

-- 注意，谓词不应该修改参数
---@class a546.Filter
---@field predicate fun(resource:a546.Resource):boolean
local Filter = O:extend()

---@cast Filter +fun(predicate:fun(resource:a546.Resource):boolean):a546.Filter
function Filter:new(predicate)
    self.predicate = predicate or function()
        return true
    end
end

--- AND
---@param filter a546.Filter
---@return a546.Filter
function Filter:And(filter)
    return Filter(function(resource)
        return self.predicate(resource) and filter.predicate(resource)
    end)
end

--- OR
---@param filter a546.Filter
---@return a546.Filter
function Filter:Or(filter)
    return Filter(function(resource)
        return self.predicate(resource) or filter.predicate(resource)
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
