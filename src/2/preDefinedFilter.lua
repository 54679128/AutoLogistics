local Filter = require("Filter")
local out = {}

--- 按名过滤
---@param name string
---@return a546.Filter
function out.withName(name)
    return Filter(function(itemStack)
        if itemStack.name == name then
            return true
        end
        return false
    end)
end

--- 按标签过滤
---@param tag string
---@return a546.Filter
function out.withTag(tag)
    return Filter(function(itemStack)
        if itemStack.tags and itemStack.tags[tag] then
            return true
        end
        return false
    end)
end

--- 按nbt过滤
---@param nbt string
---@return a546.Filter
function out.withNbt(nbt)
    return Filter(function(itemStack)
        if itemStack.nbt and itemStack.nbt == nbt then
            return true
        end
        return false
    end)
end

--- 按显示名称过滤
---@param displayName string
---@return a546.Filter
function out.withDisplayName(displayName)
    return Filter(function(itemStack)
        if itemStack.displayName and itemStack.displayName == displayName then
            return true
        end
        return false
    end)
end

return out
