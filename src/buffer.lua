---@module "Buffer"

---@class a54679128.Buffer
---@field storge table<any,string> 储存一系列通用存储外设名
local buffer = {}
buffer.__index = buffer

---一个或一组容器作为缓存
---@param peripheralNames ccTweaked.peripherals.Inventory
---@return a54679128.Buffer
function buffer:asBuffer(peripheralNames)
    if type(peripheralNames) == "string" then
        peripheralNames = { peripheralNames }
    end
    print(textutils.serialise(peripheralNames))
    local o = {}
    o.storge = {}
    for _, peripheralName in pairs(peripheralNames) do
        local comStorge = peripheral.wrap(peripheralName)
        if not comStorge then
            error(peripheralName .. " is't a peripheral or doesn't exist", 2)
        end
        table.insert(o.storge, peripheralName)
    end
    return setmetatable(o, buffer)
end

---从一个或一组容器中向缓存中输入素材
---暂时想不到如何检测是否有足够的空间储存输入素材
---@param fromNames string|table<any,string> 储存待输入素材的容器名
---@return boolean
---@return string|nil
function buffer:input(fromNames)
    if type(fromNames) == "string" then
        fromNames = { fromNames }
    end
    -- fromNames是空的
    if not next(fromNames) then
        error("fromNames is a space", 2)
    end
    for _, sourceName in pairs(fromNames) do
        -- 因为getItemDetail很耗时间，所以我尽可能的不用它，这限制了很多事
        -- 提取该输入的所有原料到缓存中
        for _, storgeName in pairs(self.storge) do
            local maxTry = 100
            local comStorge = peripheral.wrap(storgeName)
            ---@cast sourceName string
            local sourceStorge = peripheral.wrap(sourceName)
            if not comStorge or not sourceStorge then
                error("something go wrong", 2)
            end
            if comStorge.list and sourceStorge.list then
                local itemList = sourceStorge.list()
                for slot, itemInfo in pairs(itemList) do
                    local tryTimes = 0
                    while true do
                        local moveItemCount = sourceStorge.pushItems(storgeName, slot)
                        tryTimes = tryTimes + 1
                        if moveItemCount == 0 then
                            break
                        end
                        if tryTimes > maxTry then
                            break
                        end
                    end
                end
            end
            if comStorge.tanks and sourceStorge.tanks then
                local fluidTanks = sourceStorge.tanks()
                for IDontKnowWhatWasThat, fluidInfo in pairs(fluidTanks) do
                    local tryTimes = 0
                    while true do
                        local moveFluidAmount = sourceStorge.pushFluid(storgeName, fluidInfo.amount, fluidInfo.name)
                        tryTimes = tryTimes + 1
                        if moveFluidAmount == 0 then
                            break
                        end
                        if tryTimes > maxTry then
                            break
                        end
                    end
                end
            end
            -- 如果该输入已空，则直接跳出循环
            local itemState = false
            local fluidState = false
            if sourceStorge.list and (not next(sourceStorge.list())) then
                itemState = true
            elseif not sourceStorge.list then
                itemState = true
            end
            if sourceStorge.tanks and (not next(sourceStorge.tanks())) then
                fluidState = true
            elseif not sourceStorge.tanks then
                fluidState = true
            end
            if itemState and fluidState then
                break
            end
        end
    end
    for _, sourceName in pairs(fromNames) do
        local comStorge = peripheral.wrap(sourceName)
        if not comStorge then
            error("something go wrong", 2)
        end
        -- 经过所有处理后有一个输入不为空
        if comStorge.list and next(comStorge.list()) then
            -- 由于检查了所有缓存，如果输入还有别的东西，那么可以直接报错了
            -- 也许以后我会写个撤回操作，但现在我只想写个简单的报错
            error("Insufficient cache", 2)
        end
        if comStorge.tanks and next(comStorge.tanks()) then
            -- 由于检查了所有缓存，如果输入还有别的东西，那么可以直接报错了
            -- 也许以后我会写个撤回操作，但现在我只想写个简单的报错
            error("Insufficient cache", 2)
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
    local itemList = self.inventory.list()
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

---就像正常的通用外设
---@return table<number, ccTweaked.peripherals.inventory.item>
function buffer:list()
    return self.inventory.list()
end

---缓存大小
---@return number
function buffer:size()
    return buffer.inventory.size()
end

return buffer
