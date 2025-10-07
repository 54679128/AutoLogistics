---@module "Buffer"

---@class a54679128.Buffer
---@field private storge table<any,string> 储存一系列通用存储外设名
---@field storgeList table<string,table<string,number|string>> 储存缓存中的物品位于何处，数量分别为多少
local buffer = {}
buffer.__index = buffer

---一个或一组容器作为缓存
---@param peripheralNames string|table<number,string>
---@return a54679128.Buffer
function buffer:asBuffer(peripheralNames)
    if type(peripheralNames) == "string" then
        peripheralNames = { peripheralNames }
    end
    print(textutils.serialise(peripheralNames))
    local o = {}
    o.storge = {}
    o.storgeList = {}
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
        error("fromNames is a something else", 2)
    end
    -- 考虑到MC多模组环境下的复杂性，想要在物品输入前判断缓存是否有足够的空间容纳物品是不可能的。例如精妙存储，这个模组的容器内每格存储上限超过万亿也不是不可能，而且对于原版不可堆叠的物品也会适当提升其堆叠上限。这使得很难判断物品是否能塞入缓存。
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
                        if not self.storgeList[itemInfo.name] then
                            self.storgeList[itemInfo.name] = {}
                            self.storgeList[itemInfo.name][storgeName] = 0
                            self.storgeList[itemInfo.name]["Type"] = "item"
                        end
                        self.storgeList[itemInfo.name][storgeName] = self.storgeList[itemInfo.name][storgeName] +
                            moveItemCount
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
                        if not self.storgeList[fluidInfo.name] then
                            self.storgeList[fluidInfo.name] = {}
                            self.storgeList[fluidInfo.name][storgeName] = 0
                            self.storgeList[fluidInfo.name]["Type"] = "fluid"
                        end
                        self.storgeList[fluidInfo.name][storgeName] = self.storgeList[fluidInfo.name][storgeName] +
                            moveFluidAmount
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
---@param name string 素材id
---@param count number 需要转移的数量
---@return boolean
---@return string|nil
function buffer:output(toName, name, count)
    local sourcePerName = {}
    --确定是否有足够的物品
    if not self.storgeList[name] then
        return false, "The raw material does not exist in the buffer"
    end
    local k = 0
    for sourceName, num in pairs(self.storgeList[name]) do
        if type(num) == "string" then
            goto continue
        end
        table.insert(sourcePerName, sourceName)
        k = k + num
        if k >= count then
            break
        end
        ::continue::
    end
    if k < count then
        return false, "There is not enough of this material in the buffer"
    end
    --输出
    local needTransfer = count
    for _, sourceName in pairs(sourcePerName) do
        local target = peripheral.wrap(toName)
        if not target then
            return false, "The target peripheral does not exist"
        end
        -- 有个问题：怎样知道要转移的原料是流体还是物品？
        -- 我决定在storgeList中加入一个特殊Key:Type储存这些信息
        if self.storgeList[name].Type == "fluid" then
            local b = target.pullFluid(sourceName, needTransfer, name)
            needTransfer = needTransfer - b
        elseif self.storgeList[name].Type == "item" then
            local source = peripheral.wrap(sourceName)
            -- 模块内部发生的错误
            if not source then
                error("something wrong", 2)
            end
            for slot, itemInfo in pairs(source.list()) do
                if itemInfo.name == name then
                    -- 注意这里还要处理目标容器是否有足够的空间储存，记得后面加上
                    while true do
                        local b = target.pullItems(sourceName, slot, needTransfer)
                        needTransfer = needTransfer - b
                        if b == 0 then
                            break
                        end
                    end
                end
            end
        end
    end
    return true, nil
end

---返回缓存中所储存的原料列表
---@return table<string,table<string,number|string>> {name = {type = "fluid"|"item",num = number},...}
function buffer:list()
    local result = {}
    for name, inv in pairs(self.storgeList) do
        if result[name] == nil then
            result[name] = { type = nil, num = 0 }
        end
        for _, num in pairs(inv) do
            if type(num) == "string" then
                result[name].type = num
                goto continue
            end
            result[name].num = result[name].num + num
            ::continue::
        end
    end
    return result
end

return buffer
