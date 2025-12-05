local O = require("lib.Object")

---@class a546.ItemStack
---@field count number 对于流体，这代表 amount
---@field displayName string|nil
---@field itemGroups {displayName:string,id:string}[]|{}
---@field maxCount number|nil
---@field name string
---@field tags table<string,boolean>|nil
---@field nbt string|nil

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
---@param filiter a546.Filter
---@return a546.Filter
function Filter:And(filiter)
    return Filter(function(ItemStack)
        return self.predicate(ItemStack) and filiter.predicate(ItemStack)
    end)
end

--- OR
---@param filiter a546.Filter
---@return a546.Filter
function Filter:Or(filiter)
    return Filter(function(ItemStack)
        return self.predicate(ItemStack) or filiter.predicate(ItemStack)
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
