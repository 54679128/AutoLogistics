---@module "buffer"

---@class a54679128.Buffer
---@field inventory ccTweaked.peripherals.Inventory
local buffer = {}
buffer.__index = buffer

---将该容器作为一个缓存
---@param inventory ccTweaked.peripherals.Inventory
---@return a54679128.Buffer
function buffer:asBuffer(inventory)
    local o = {}
    o.inventory = inventory
    return setmetatable(o, buffer)
end

---向缓存中输入物品
---@param fromName string 储存待输入物品的容器名
---@param slot number? 待输入物品所在槽位
---@return boolean
---@return string|nil
function buffer:input(fromName, slot)
    --梦游时写的
    if not fromName or type(fromName) ~= "string" or not peripheral.wrap(fromName) then end

    local maxTries = 100
    local input = peripheral.wrap(fromName)
    if input == nil then
        return false, "The peripheral doesn't exist"
    end
    local content = input.list()
    --[[
    local needTransfer = {}
    for slot, item in pairs(content) do
        needTransfer[slot] = item.count
    end
    --]]
    for iSlot, item in pairs(content) do
        local count = item.count
        local willTransfer = 0
        local times = 0
        while true do
            willTransfer = willTransfer + self.inventory.pullItems(fromName, iSlot)
            if willTransfer == count or times > maxTries then
                break
            end
            times = times + 1
        end
    end
    return true, nil
end

---输出
---@param toName string 目标容器名
---@param itemName string 物品id
---@param count number 需要转移的数量
---@return boolean
---@return string|nil
function buffer:output(toName, itemName, count)
    --确定是否有足够的物品
    local itemList = buffer.inventory.list()
    local k = 0 --储存当前容器物品数，暂时不知道怎么命名
    for slot, item in pairs(itemList) do
        if item.name == itemName then
            k = k + item.count
        end
    end
    if k < count then
        return false, "Not enough items"
    end
    --输出
    local hasTransfer = 0 --记录已转移物品数，暂时不知道怎么命名
    for slot, item in pairs(itemList) do
        if item.name ~= itemName then
            goto continue
        end
        --如果目的地容器的槽位可以存储的最大物品数量小于缓存，需要多次转移
        while true do
            local hgk = self.inventory.pushItems(toName, slot, count - hasTransfer) --记录这次转移了多少物品，暂时不知道怎么命名
            hasTransfer = hasTransfer + hgk
            if hgk == 0 then
                break
            end
        end
        ::continue::
    end
    return true, nil
end

---缓存大小
---@return number
function buffer:size()
    return buffer.inventory.size()
end

return buffer
