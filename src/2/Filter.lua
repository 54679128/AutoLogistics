local O = require("lib.Object")

---@class a546.Filter
---@field predicate fun(ItemStack:a546.ItemStack):boolean
local Filter = O:extend()

---@cast Filter +fun(predicate:fun(ItemStack:a546.ItemStack):boolean):a546.Filter
function Filter:new(predicate)
    self.predicate = predicate or function()
        return true
    end
end

--- AND
---@param filter a546.Filter
---@return a546.Filter
function Filter:And(filter)
    return Filter(function(ItemStack)
        return self.predicate(ItemStack) and filter.predicate(ItemStack)
    end)
end

--- OR
---@param filter a546.Filter
---@return a546.Filter
function Filter:Or(filter)
    return Filter(function(ItemStack)
        return self.predicate(ItemStack) or filter.predicate(ItemStack)
    end)
end

--- NOT
---@return a546.Filter
function Filter:Not()
    return Filter(function(ItemStack)
        return not self.predicate(ItemStack)
    end)
end

return Filter
