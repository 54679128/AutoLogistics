local Object = require("lib.Object")
local log = require("lib.log")
log.outfile("log.txt")

---@class a546.ContainerStack
---@field private slots table<number,a546.ItemStack> 键为槽位，值为物品栈
---@field size number
---@field updateTime number 本地时间戳
---@field peripheralName string
local ContainerStack = Object:extend()

---@cast ContainerStack +fun():a546.ContainerStack
function ContainerStack:new()
    self.slots = {}
    self.size = nil
    self.updateTime = nil
    self.peripheralName = nil
end

--- 复制 tCS 除 slots 以外的字段
---@param tCS a546.ContainerStack
local function copy(tCS)
    local newCS = ContainerStack()
    newCS.peripheralName = tCS.peripheralName
    newCS.size = tCS.size
    newCS.updateTime = tCS.updateTime
    return newCS
end

--- 刚创建的 ContainerStack 需要使用这个方法初始化
---@param peripheralName string
---@return nil|a546.ContainerStack
---@return string|nil errorMessage
function ContainerStack:scan(peripheralName)
    local scanObj = peripheral.wrap(peripheralName)
    if not scanObj then
        log.warn(("peripheral %s can't find"):format(peripheralName))
        return nil, ("peripheral %s can't find"):format(peripheralName)
    end
    self.size = scanObj.getSize()
    for i = 1, self.size, 1 do
        self.slots[i] = scanObj.getItemDetail(i)
    end
    self.updateTime = os.time("local")
    self.peripheralName = peripheralName
    return self
end

--- 获取内部储存的一个副本
---@return table<number,a546.ItemStack>|nil # 键为槽位，值为物品栈
function ContainerStack:getAll()
    ---@diagnostic disable-next-line: redundant-parameter
    return textutils.unserialise(textutils.serialise(self.slots), { allow_repetitions = true })
end

--- 从本容器中移除指定槽位，并返回包含这些物品的新 ContainerStack
---@param index number|number[]
---@return a546.ContainerStack
function ContainerStack:extract(index)
    if type(index) == "number" then
        index = { index }
    end
    local newCS = copy(self)
    for _, i in pairs(index) do
        local temp = self.slots[i]
        self.slots[i] = nil
        newCS.slots[i] = temp
    end
    return newCS
end

--- 合并指定的 a546.ContainerStack 。两个 ContainerStack 需要拥有相同的 peripheralName。不处理冲突等复杂情况，只在 有空位时合并。
---@param tCS a546.ContainerStack
---@return a546.ContainerStack|nil
---@return string|nil
function ContainerStack:merge(tCS)
    if tCS.peripheralName ~= self.peripheralName then
        return nil, ("peripheral %s is't %s"):format(tCS.peripheralName, self.peripheralName)
    end
    for slot, itemStack in pairs(tCS.slots) do
        if self.slots[slot] == nil then
            self.slots[slot] = itemStack
        end
    end
    return self
end

return ContainerStack
