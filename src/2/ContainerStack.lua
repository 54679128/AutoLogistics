local Object = require("lib.Object")
local log = require("lib.log")
local util = require("lib.util")
local itemCommand = require("commands.TransferSlotToInventory")
local fluidCommand = require("commands.TransferFluid")
local invoker = require("CommandInvoker")
log.outfile = "log.txt"

---@alias lockId string
---@alias slotOrName number|string
---@alias resourceSlots table<slotOrName|string,a546.ItemStack>

---@class a546.ItemStack
---@field count number 对于流体，这代表 amount
---@field displayName string|nil
---@field itemGroups {displayName:string,id:string}[]|{}
---@field maxCount number|nil
---@field name string
---@field tags table<string,boolean>|nil
---@field nbt string|nil

---@class a546.ContainerStack
---@field private slots resourceSlots 键为槽位或流体名，值为物品栈。这个字段用于储存可被调用的物品或流体。
---@field private locks table<lockId,resourceSlots> # <Id:string|lockSlots:table<slotOrName:number|string,itemOrFluidStack:a546.ItemStack>>
---@field size number|nil 如果该容器只能储存流体，则该字段为 nil
---@field updateTime number 本地时间戳
---@field peripheralName string
local ContainerStack = Object:extend()

---@cast ContainerStack +fun():a546.ContainerStack
function ContainerStack:new()
    self.slots = {}
    self.locks = {}
    self.size = nil
    self.updateTime = nil
    self.peripheralName = nil
end

--- 检查该ContainerStack是否可以进行探测
---@return boolean
function ContainerStack:checkCanScan()
    if next(self.locks) then
        return false
    end
    return true
end

function ContainerStack:saveAsFile(outFile)
    local file = io.open(outFile, "w+")
    assert(file, ("can't open %s"):format(outFile))
    file:write(textutils.serialise(self, { allow_repetitions = true }))
end

function ContainerStack:reloadFromFile(reloadFile)
    local file = io.open(reloadFile, "r")
    assert(file, ("can't open %s"):format(reloadFile))
    file:seek("set")
    local cStr = textutils.unserialise(file:read("a"))
    ---@cast cStr a546.ContainerStack
    for k, v in pairs(cStr) do
        self[k] = v
    end
end

--- 刚创建的 ContainerStack 需要使用这个方法初始化
---@param peripheralName string
---@return nil|a546.ContainerStack
---@return string|nil errorMessage
function ContainerStack:scan(peripheralName)
    -- 判断是否可以执行检测
    if not self:checkCanScan() then
        log.warn(("Try to update ContainerStack %s which have some locking"):format(self.peripheralName))
        return
    end
    local scanObj = peripheral.wrap(peripheralName)
    -- 一些简单的检查，我期望以后会写一个自定义外设类来解决这些烦人的问题
    if not scanObj then
        log.warn(("peripheral %s can't find"):format(peripheralName))
        return nil, ("peripheral %s can't find"):format(peripheralName)
    end
    if scanObj.tanks then
        for _, fluidInfo in pairs(scanObj.tanks()) do
            -- 由于流体和物品的格式不一样，这里要整理一下
            local itemFormat = {
                count = fluidInfo.amount,
                name = fluidInfo.name
            }
            ---@cast itemFormat +a546.ItemStack
            self.slots[fluidInfo.name] = itemFormat
        end
    end
    if scanObj.list then
        self.size = scanObj.size()
        for slot, _ in pairs(scanObj.list()) do
            self.slots[slot] = scanObj.getItemDetail(slot)
        end
        --[[
        for i = 1, self.size, 1 do
            self.slots[i] = scanObj.getItemDetail(i)
        end
        ]]
    end
    self.updateTime = os.epoch("local")
    self.peripheralName = peripheralName
    return self
end

--- 刚创建的 ContainerStack 需要使用这个方法初始化。这个方法只处理能容纳物品的容器
---@param peripheralName string
---@param slot number
---@return nil|a546.ContainerStack
function ContainerStack:scanBySlot(peripheralName, slot)
    -- 判断是否可以执行检测
    if not self:checkCanScan() then
        log.warn(("Try to update ContainerStack %s which have some locking"):format(self.peripheralName))
        return
    end
    local scanObj = peripheral.wrap(peripheralName)
    if not scanObj then
        log.warn(("peripheral %s can't find"):format(peripheralName))
        return nil
    end

    self.size = scanObj.size()
    self.slots[slot] = scanObj.getItemDetail(slot)
    self.updateTime = os.epoch("local")
    self.peripheralName = peripheralName
    return self
end

--- 获取内部可用储存的一个副本
---@return table<number|string,a546.ItemStack>|{} # 键为槽位或流体名，值为物品栈
function ContainerStack:getContext()
    return util.copyTable(self.slots)
end

--- 从本容器中可用储存中移除指定槽位/名称，并转移至不可用/锁定储存。
---@param index number|number[]|string|string[]
---@return string id
function ContainerStack:lock(index)
    -- 参数处理
    if type(index) == "number" or type(index) == "string" then
        index = { index }
    end
    -- 检查物品是否存在
    for _, slotOrName in pairs(index) do
        if not self.slots[slotOrName] then
            local errMessage = ("Slot %d does't have item or name %s does't exist"):format(slotOrName,
                tostring(slotOrName))
            log.error(errMessage)
            error(errMessage)
        end
    end
    local targetLockId = util.generateRandomString(math.random(50, 100))
    self.locks[targetLockId] = {}
    local tLock = self.locks[targetLockId]
    for _, i in pairs(index) do
        local temp = self.slots[i]
        self.slots[i] = nil
        tLock[i] = temp
    end
    return targetLockId
end

--- 从本容器中减少指定槽位/名称的物品/流体的数量，并转移至不可用/锁定储存。
---@param index {slotOrName:string|number,countOrAmount:number}[]
---@return string id
function ContainerStack:lockByCount(index)
    -- 检查是否能够执行要求的操作
    for i, v in pairs(index) do
        if not self.slots[v.slotOrName] then
            local errMessage = ("Index ask item/fluid: %s does't exist"):format(v.slotOrName)
            log.error(errMessage)
            error(errMessage)
        end
        if self.slots[v.slotOrName].count < v.countOrAmount then
            log.error(("Index %d not enough quantity. Inventory: %d, Ask: %d"):format(i, self.slots[v.slotOrName].count,
                v.countOrAmount))
            error(("Index %d not enough quantity. Inventory: %d, Ask: %d"):format(i, self.slots[v.slotOrName].count,
                v.countOrAmount))
        end
    end
    -- 检查通过，开始处理转移逻辑
    local targetLockId = util.generateRandomString(math.random(50, 100))
    self.locks[targetLockId] = {}
    local tLock = self.locks[targetLockId]
    for _, v in pairs(index) do
        local sourceStack = self.slots[v.slotOrName]
        tLock[v.slotOrName] = util.copyTable(sourceStack)
        sourceStack.count = sourceStack.count - v.countOrAmount
        tLock[v.slotOrName].count = v.countOrAmount
        -- 如果 sourceStack.count 为零，可以直接删掉
        if sourceStack.count == 0 then
            self.slots[v.slotOrName] = nil
        end
    end
    return targetLockId
end

--- 消耗或提取锁定的物品
---@param id lockId
---@return fun(peripheralName:string)|nil
function ContainerStack:consumeLock(id)
    ---@type table<number,{slotOrName:slotOrName,countOrAmount:number}>
    local result = {}
    -- 判断是否有符合钥匙的锁
    if not self.locks[id] then
        log.error(("Key %s can't open peripheral %s's any lock"):format(id, self.peripheralName))
    end
    -- 从锁中提取相关信息
    for slotOrName, itemStack in pairs(self.locks[id]) do
        local temp = {
            slotOrName = slotOrName,
            countOrAmount = itemStack.count
        }
        table.insert(result, temp)
    end
    -- 将锁定资源转移至新的锁下存放
    local newRandomKey = util.generateRandomString(10)
    self.locks[newRandomKey] = self.locks[id]
    self.locks[id] = nil
    return function(targetPeripheralName)
        -- 首先判断源容器是否有足够的资源
        local errMessage = ("Peripheral %s doesn't exsit"):format(self.peripheralName)
        local container = peripheral.wrap(self.peripheralName)
        if not container then
            log.error(errMessage)
            error(errMessage)
        end
        -- 如果是物品容器
        if container.list then
            local itemList = container.list()
            for slotOrName, itemStack in pairs(self.locks[newRandomKey]) do
                -- 原外设是空的
                -- 这个判断可以放在for外面，但放在里面比较整齐
                if not itemList then
                    errMessage = ("Perhiperal %s is empty of item"):format(self.peripheralName)
                    log.error(errMessage)
                    -- 这里可能还需要一些额外的处理
                    error(errMessage)
                end
                -- 物品存在但少于需求的数量
                if itemList[slotOrName] and itemList[slotOrName].count < itemStack.count then
                    errMessage = ("Peripheral %s doesn't have enough item %s:\nNeed: name:%s, count:%s\nHave: name:%s, count:%s")
                        :format(self.peripheralName, itemStack.name, itemStack.name, itemStack.count,
                            itemList[slotOrName].name, itemList[slotOrName].count)
                    log.error(errMessage)
                    error(errMessage)
                end
                -- 物品不存在
                if not itemList[slotOrName] then
                    errMessage = ("Peripheral %s doesn't have item %s"):format(self.peripheralName, itemStack.name)
                    log.error(errMessage)
                    error(errMessage)
                end
            end
        end
        -- 如果是流体容器
        if container.tanks then
            local fluidList = container.tanks()
            local resourceSlots = self.locks[newRandomKey]
            for _, fluidStack in pairs(fluidList) do
                -- 流体容器是空的
                if not fluidList then
                    errMessage = ("Perhiperal %s is empty of fluid"):format(self.peripheralName)
                    log.error(errMessage)
                    -- 这里可能还需要一些额外的处理
                    error(errMessage)
                end
                -- 需要的流体不存在
                if not resourceSlots[fluidStack.name] then
                    errMessage = ("Peripheral %s doesn't have fluid %s"):format(self.peripheralName, fluidStack.name)
                    log.error(errMessage)
                    error(errMessage)
                end
                -- 需要的流体存在但数量不足
                if resourceSlots[fluidStack.name].count > fluidStack.amount then
                    errMessage = ("Peripheral %s doesn't have enough fluid %s:\nNeed: name:%s, amount:%s\nHave: name:%s, amount:%s")
                        :format(self.peripheralName, fluidStack.name, fluidStack.name, fluidStack.amount,
                            resourceSlots[fluidStack.name].name, resourceSlots[fluidStack.name].count)
                    log.error(errMessage)
                    error(errMessage)
                end
            end
        end
        -- 我本来想接着判断目标容器是否有足够的空间（这在流体上有些问题，cc的通用流体外设没有提供检查流体容器的方法），但我想到涉及到某些mod时，没有任何办法检查它们是否可以通过接收所要传输的物品。你只能尝试传输，然后检查传输是否失败。

        local output = invoker()
        for _, v in pairs(result) do
            -- 流体和物品用不同的命令
            if type(v.slotOrName) == "string" then
                output:addCommand(fluidCommand(self.peripheralName, targetPeripheralName, v.countOrAmount,
                    v.slotOrName --[[@as string]]))
            else
                output:addCommand(itemCommand(self.peripheralName, targetPeripheralName, v.slotOrName --[[@as number]],
                    v.countOrAmount))
            end
        end
        output:processAll()
        -- 使用后删除锁定资源
        self.locks[newRandomKey] = nil
    end
end

--- 使用 lock 系列函数给出的 id 解锁物品或流体
---@param id lockId
function ContainerStack:unLock(id)
    local processTable = self.locks[id]
    -- id不存在
    if not processTable then
        local errMessage = ("Lock id:%s doen's exist"):format(id)
        log.error(errMessage)
        error(errMessage)
        return
    end
    for i, v in pairs(processTable) do
        if not self.slots[i] then
            self.slots[i] = v
            --processTable[i] = nil 最后会丢弃整个表，在这里设置毫无意义
            goto continue
        end
        self.slots[i].count = self.slots[i].count + v.count
        ::continue::
    end
    -- 处理完毕，丢弃
    self.locks[id] = nil
end

return ContainerStack
