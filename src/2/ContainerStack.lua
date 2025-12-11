local Object = require("lib.Object")
local log = require("lib.log")
local util = require("lib.util")
log.outfile = "log.txt"

---@class a546.ItemStack
---@field count number 对于流体，这代表 amount
---@field displayName string|nil
---@field itemGroups {displayName:string,id:string}[]|{}
---@field maxCount number|nil
---@field name string
---@field tags table<string,boolean>|nil
---@field nbt string|nil

---@class a546.Resource
---@field name string 资源名称
---@field quantity number 资源数量
---@field resourceType "item"|"fluid"|string
---@field nbt string|nil 这个 NBT 数据没有包含任何有用的信息，但允许你区分相同的物品
---@field detail nil|(fun():a546.ItemStack|nil)

---@alias SlotOrName string|number # 数字槽位、字符串代表流体名

---@alias LockReceipt string # 票据

---@class a546.ContainerStack
---@field private slots table<SlotOrName,a546.Resource> 键为槽位或流体名，值为物品栈。这个字段用于储存可被调用的物品或流体。
---@field private locks table <LockReceipt,table<SlotOrName,a546.Resource>> # <Id:number|lockSlots:table<slotOrName:number|string,itemOrFluidStack:a546.ItemStack>>
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

--- 判断输入外设名所代表的外设是否为一个容器。
---@param peripheralName string
---@return boolean
function ContainerStack.isContainer(peripheralName)
    local per = peripheral.wrap(peripheralName)
    local errMessage
    if not per then
        errMessage = ("Peripheral %s doesn't exist"):format(peripheralName)
        log.error(errMessage)
        return false
    end
    -- 物品容器
    if per.list and per.pullItems and per.pushItems then
        return true
    end
    -- 流体容器
    if per.tanks and per.pushFluid and per.pullFluid then
        return true
    end
    return false
end

--- 删除某个锁
---@param lockReceipt LockReceipt
function ContainerStack:abolishLock(lockReceipt)
    if not self.locks[lockReceipt] then
        return
    end
    self.locks[lockReceipt] = nil
end

--- 判断该锁是否可用
---@param lockReceipt LockReceipt
---@return boolean
function ContainerStack:isAvailable(lockReceipt)
    local errMessage
    -- 检查锁是否存在
    if not self.locks[lockReceipt] then
        return false
    end
    -- 检查外设是否存在
    local per = peripheral.wrap(self.peripheralName)
    if not per then
        errMessage = ("Peripheral %s doesn't exsit"):format(self.peripheralName)
        log.warn(errMessage)
        return false
    end
    local itemList
    local fluidList
    if per.list then
        itemList = per.list()
    end
    if per.tanks then
        fluidList = per.tanks()
    end
    for slotOrName, resource in pairs(self.locks[lockReceipt]) do
        -- 如果是流体
        if type(slotOrName) == "string" then
            for _, fluidInfo in pairs(fluidList) do
                if fluidInfo.name ~= slotOrName then
                    goto continue
                end
                if fluidInfo.amount < resource.quantity then
                    self.locks[lockReceipt] = nil
                    return false
                end
                ::continue::
            end
        else -- 如果是物品
            if not itemList[slotOrName] then
                self.locks[lockReceipt] = nil
                return false
            end
            if itemList[slotOrName].count < resource.quantity then
                self.locks[lockReceipt] = nil
                return false
            end
        end
    end
    return true
end

--- 更新指定容器缓存
---@param slotOrName SlotOrName|nil
---@return boolean success
function ContainerStack:updata(slotOrName)
    local errMessage
    local per = peripheral.wrap(self.peripheralName)
    if not per then
        errMessage = ("Peripheral %s doesn't exist"):format(self.peripheralName)
        log.error(errMessage)
        return false
    end
    if type(slotOrName) == "string" then
        if not per.tanks then
            errMessage = ("Try to updata unist resource: %s in peripheral %s"):format(slotOrName, self.peripheralName)
            log.warn(errMessage)
            return false
        end
        local fluidList = per.tanks()
        for _, fluidInfo in pairs(fluidList) do
            if fluidInfo.name == slotOrName then
                ---@type a546.Resource
                local resourceFormat = {
                    name = slotOrName,
                    quantity = fluidInfo.amount,
                    resourceType = "fluid"
                }
                self.slots[slotOrName] = resourceFormat
                return true
            end
        end
    elseif type(slotOrName) == "number" then
        if not per.list then
            errMessage = ("Try to updata unacceptable resource: item in peripheral %s"):format(
                self.peripheralName)
            log.warn(errMessage)
            return false
        end
        local itemList = per.list()
        if not itemList[slotOrName] then
            errMessage = ("Try to updata slot of unist resource in peripheral %s"):format(self
                .peripheralName)
            log.warn(errMessage)
            return true
        end
        ---@type a546.Resource
        local resourceFormat = {
            name = itemList[slotOrName].name,
            quantity = itemList[slotOrName].count,
            nbt = itemList[slotOrName].nbt,
            detail = function()
                local rep = peripheral.wrap(self.peripheralName)
                if not rep then
                    log.warn("Peripheral %s doesn't exist"):format(self.peripheralName)
                    return nil
                end
                if not rep.getItemDetail then
                    return nil
                end
                return rep.getItemDetail(slotOrName)
            end,
            resourceType = "item"
        }
        self.slots[slotOrName] = resourceFormat
    else
        self:scan(self.peripheralName)
    end
    return true
end

function ContainerStack:saveAsFile(outFile)
    local file = io.open(outFile, "w+")
    assert(file, ("can't open %s"):format(outFile))
    -- 函数无法被序列化，所以预先删除
    for _, resource in pairs(self.slots) do
        resource.detail = nil
    end
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
    -- 回复在保存为文件前被删除的 detail 函数
    for slotOrName, resource in pairs(self.slots) do
        if type(slotOrName) == "string" then
            goto continue
        end
        resource.detail = function()
            local tempPer = peripheral.wrap(self.peripheralName)
            if not tempPer then
                log.warn(("peripheral %s can't find"):format(self.peripheralName))
                return nil
            end
            return tempPer.getItemDetail(slotOrName)
        end
        ::continue::
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
    if not ContainerStack.isContainer(peripheralName) then
        local errMessage = ("Peripheral %s is't a Container"):format(peripheralName)
        log.error(errMessage)
        return nil, errMessage
    end
    if scanObj.tanks then
        for _, fluidInfo in pairs(scanObj.tanks()) do
            -- 由于流体和物品的格式不一样，这里要整理一下
            ---@type a546.Resource
            local resourceFormat = {
                name = fluidInfo.name,
                quantity = fluidInfo.amount,
                resourceType = "fluid"
            }
            self.slots[fluidInfo.name] = resourceFormat
        end
    end
    if scanObj.list then
        local itemList = scanObj.list()
        for slot, itemInfo in pairs(itemList) do
            ---@type a546.Resource
            local resourceFormat = {
                name = itemInfo.name,
                quantity = itemInfo.count,
                resourceType = "item",
                nbt = itemInfo.nbt,
                detail = function()
                    local tempPer = peripheral.wrap(peripheralName)
                    if not tempPer then
                        log.warn(("peripheral %s can't find"):format(peripheralName))
                        return nil
                    end
                    return tempPer.getItemDetail(slot)
                end
            }
            self.slots[slot] = resourceFormat
        end
    end
    self.size = scanObj.size()
    self.updateTime = os.epoch("local")
    self.peripheralName = peripheralName
    return self
end

--- 刚创建的 ContainerStack 需要使用这个方法初始化。这个方法只处理能容纳物品的容器
---@param peripheralName string
---@param slot number
---@return nil|a546.ContainerStack
function ContainerStack:scanBySlot(peripheralName, slot)
    -- 检查外设上是否存在
    local scanObj = peripheral.wrap(peripheralName)
    if not scanObj then
        log.warn(("peripheral %s can't find"):format(peripheralName))
        return nil
    end
    if not ContainerStack.isContainer(peripheralName) then
        local errMessage = ("Peripheral %s is't a Container"):format(peripheralName)
        log.error(errMessage)
        return nil
    end
    -- 检查该槽位是否存在
    if slot > scanObj.size() then
        log.warn(("peripheral %s doesn't have this slot %d"):format(peripheralName, slot))
        return nil
    end
    local itemList = scanObj.list()
    -- 检查该槽位是否存在物品
    if not itemList[slot] then
        log.warn(("peripheral %s doesn't have item in slot %d"):format(peripheralName, slot))
        return nil
    end
    -- 构造 Resource
    ---@type a546.Resource
    local resourceFormat = {
        name = itemList[slot].name,
        quantity = itemList[slot].count,
        resourceType = "item",
        nbt = itemList[slot].nbt,
        detail = function()
            local tempPer = peripheral.wrap(peripheralName)
            if not tempPer then
                log.warn(("peripheral %s can't find"):format(peripheralName))
                return nil
            end
            return tempPer.getItemDetail(slot)
        end
    }
    self.size = scanObj.size()
    self.slots[slot] = resourceFormat
    self.updateTime = os.epoch("local")
    self.peripheralName = peripheralName
    return self
end

--- 获取内部可用储存的一个副本
---@return table<SlotOrName,a546.Resource>|{} # 键为槽位或流体名，值为物品栈
function ContainerStack:getContext()
    return util.copyTable(self.slots)
end

--- 获取内部锁定表的一个副本。这个函数之应该用于debug。
---@return table<string, table<string|number, a546.Resource>>
function ContainerStack:getLock()
    return util.copyTable(self.locks)
end

--- 根据票据返回对应的锁的内容
---@param lockReceipt LockReceipt
---@return table<string|number, a546.Resource>|nil
function ContainerStack:getResource(lockReceipt)
    return util.copyTable(self.locks[lockReceipt])
end

--- 从本容器中可用储存中移除指定槽位/名称，并转移至不可用/锁定储存。
---@param index number|number[]|string|string[]|table<any,SlotOrName>
---@return LockReceipt
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
    local targetLockId = util.generateRandomString(math.random(50, 60))
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
---@return LockReceipt
function ContainerStack:lockByCount(index)
    -- 检查是否能够执行要求的操作
    for i, v in pairs(index) do
        -- 索引中提到的槽位/流体名在可用库存中不存在物品/流体
        if not self.slots[v.slotOrName] then
            local errMessage = ("Index ask item/fluid: %s does't exist"):format(v.slotOrName)
            log.error(errMessage)
            error(errMessage)
        end
        -- 索引中要求的数量大于可用库存中拥有的数量
        if self.slots[v.slotOrName].quantity < v.countOrAmount then
            log.error(("Not have enough resource for index %d. Inventory: %d, Ask: %d"):format(i,
                self.slots[v.slotOrName].quantity,
                v.countOrAmount))
            error(("Not have enough resource for index %d. Inventory: %d, Ask: %d"):format(i,
                self.slots[v.slotOrName].quantity,
                v.countOrAmount))
        end
    end
    -- 检查通过，开始处理转移逻辑
    local lockReceipt = util.generateRandomString(math.random(50, 60))
    self.locks[lockReceipt] = {}
    local tLock = self.locks[lockReceipt]
    for _, v in pairs(index) do
        local sourceResource = self.slots[v.slotOrName]
        -- copyTable 没法完整复制 detail 函数，所以这里可能会出问题
        tLock[v.slotOrName] = util.copyTable(sourceResource)
        sourceResource.quantity = sourceResource.quantity - v.countOrAmount
        tLock[v.slotOrName].quantity = v.countOrAmount
        -- 如果 sourceStack.count 为零，可以直接删掉
        if sourceResource.quantity == 0 then
            self.slots[v.slotOrName] = nil
        end
    end
    return lockReceipt
end

--- 使用 lock 系列函数给出的 lockReceipt 解锁物品或流体
---@param lockReceipt string
function ContainerStack:unLock(lockReceipt)
    local processTable = self.locks[lockReceipt]
    -- 票据不存在
    if not processTable then
        local errMessage = ("Try to unlock unexsit lock receipt %s"):format(lockReceipt)
        log.warn(errMessage)
        -- error(errMessage)
        return
    end
    -- 合并操作
    for i, v in pairs(processTable) do
        if not self.slots[i] then
            self.slots[i] = v
            --processTable[i] = nil 最后会丢弃整个表，在这里设置毫无意义
            goto continue
        end
        self.slots[i].quantity = self.slots[i].quantity + v.quantity
        ::continue::
    end
    -- 处理完毕，丢弃
    self.locks[lockReceipt] = nil
end

return ContainerStack
