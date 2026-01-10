local Filter = require("Filter")
local out = {}

--- 按名过滤
---@param name string
---@return a546.Filter
function out.withName(name)
    return Filter(function(resource)
        if resource.name == name then
            return true
        end
        return false
    end, "With Name")
end

--- 按种类过滤
---@param resourceType "item"|"fluid"|string
---@return a546.Filter
function out.withType(resourceType)
    return Filter(function(resource)
        if resource.resourceType == resourceType then
            return true
        end
        return false
    end, "With Type")
end

--- 按堆叠数量过滤
---@param quantity number
---@return a546.Filter
function out.withQuantity(quantity)
    return Filter(function(resource)
        if resource.quantity == quantity then
            return true
        end
        return false
    end, "With Quantity")
end

--- 按标签过滤
---@param tag string
---@return a546.Filter
function out.withTag(tag)
    return Filter(function(resource)
        -- 不能存在detail函数，无法判断tag
        if not resource.detail then
            return false
        end
        local detail = resource.detail()
        -- detail函数因为某种原因失败了？
        if not detail then
            return false
        end
        if detail.tags and detail.tags[tag] then
            return true
        end
        return false
    end, "With Tag")
end

--- 按nbt过滤
---@param nbt string
---@return a546.Filter
function out.withNbt(nbt)
    return Filter(function(resource)
        if resource.nbt and resource.nbt == nbt then
            return true
        end
        return false
    end, "With Nbt")
end

--- 按显示名称过滤
---@param displayName string
---@return a546.Filter
function out.withDisplayName(displayName)
    return Filter(function(resource)
        -- 不能存在detail函数，无法判断tag
        if not resource.detail then
            return false
        end
        local detail = resource.detail()
        -- detail函数因为某种原因失败了？
        if not detail then
            return false
        end
        if detail.displayName and detail.displayName == displayName then
            return true
        end
        return false
    end, "With Display Name")
end

--- 按总数过滤
---@param limit number
---@return a546.Filter
function out.withTotalQuantity(limit)
    --- 已选取的资源总数
    local x = 0
    return Filter(function(resource)
        --[[
        local take = true
        local howMuch = 0
        if x + resource.quantity < limit then
            howMuch = resource.quantity
            x = x + resource.quantity
        elseif x == limit then
            take = false
        else
            howMuch = limit - x
            x = limit
        end
        return take, howMuch
        ]]
        if x >= limit then
            return false, 0
        end
        local howMuch = math.min(resource.quantity, limit - x)
        x = x + howMuch
        return true, howMuch
    end, "With Total Quantity")
end

return out
