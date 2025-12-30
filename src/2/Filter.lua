local O = require("lib.Object")
local util = require("lib.util")

-- 注意，谓词不应该修改参数
---@class a546.Filter
---@field predicate fun(resource:a546.Resource):boolean
---@field name string
local Filter = O:extend()

---@cast Filter +fun(predicate:(fun(resource:a546.Resource):boolean),name?:string):a546.Filter
function Filter:new(predicate, name)
    self.predicate = predicate or function()
        return true
    end
    name = name or util.generateRandomString(4)
end

function Filter:__tostring()
    return self.name
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
