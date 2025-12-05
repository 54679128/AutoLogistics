local Object = require("lib.Object")
local log = require("lib.log")
local util = require("lib.util")
log.outfile = "log.txt"

---@class a546.ContainerStack
---@field private slots table<number|string,a546.ItemStack> 键为槽位或流体名，值为物品栈。这个字段用于储存可被调用的物品或流体。
---@field private locks table <number,table<number|string,a546.ItemStack>> # <Id:number|lockSlots:table<slotOrName:number|string,itemOrFluidStack:a546.ItemStack>>
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
    local scanObj = peripheral.wrap(peripheralName)
    -- 一些简单的检查，我期望以后会写一个自定义外设类来解决这些烦人的问题
    if not scanObj then
        log.warn(("peripheral %s can't find"):format(peripheralName))
        return nil, ("peripheral %s can't find"):format(peripheralName)
    end
    if scanObj.tanks then
        for name, fluidInfo in pairs(scanObj.tanks()) do
            -- 由于流体和物品的格式不一样，这里要整理一下
            local itemFormat = {
                count = fluidInfo.amount,
                name = fluidInfo.name
            }
            ---@cast itemFormat +a546.ItemStack
            self.slots[name] = itemFormat
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
function ContainerStack:getAll()
    return util.copyTable(self.slots)
end

--- 获取内部不可用/锁定储存的一个副本
---@return table<number,a546.ItemStack>|{} # 键为槽位或流体名，值为物品栈
function ContainerStack:getLock()
    return util.copyTable(self.locks)
end

--- 从本容器中可用储存中移除指定槽位/名称，并转移至不可用/锁定储存。
---@param index number|number[]|string|string[]
---@return number id
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
    local targetLockId = os.epoch("local")
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
---@return number id
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
    local targetLockId = os.epoch("local")
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

--- 使用 lock 系列函数给出的 id 解锁物品或流体
---@param id number
function ContainerStack:unLock(id)
    local processTable = self.locks[id]
    -- id不存在
    if not processTable then
        local errMessage = ("Lock id:%d doen's exist"):format(id)
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
