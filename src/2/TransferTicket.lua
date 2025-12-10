local log = require("lib.log")
local Object = require("lib.Object")
local itemCommand = require("commands.TransferSlotToInventory")
local fluidCommand = require("commands.TransferFluid")
local invoker = require("CommandInvoker")

---@class a546.TransferTicket
---@field private containerStack a546.ContainerStack
---@field private lockReceipt LockReceipt
---@field private run boolean
local TransferTicket = Object:extend()

---@cast TransferTicket +fun(containerStack:a546.ContainerStack,lockReceipt:LockReceipt):a546.TransferTicket
function TransferTicket:new(containerStack, lockReceipt)
    self.containerStack = containerStack
    self.lockReceipt = lockReceipt
    self.run = false
end

--- 返回该支票是否可用
---@return boolean
function TransferTicket:isAvailable()
    return not self.run
end

--- 使用该支票
---@param targetPeripheralName string
---@return boolean success
function TransferTicket:execute(targetPeripheralName)
    self.run = true
    local errMessage
    -- 检查容器是否存在
    local source = peripheral.wrap(self.containerStack.peripheralName)
    if not source then
        errMessage = ("Peripheral %s doesn't exist"):format(self.containerStack.peripheralName)
        log.error(errMessage)
        self.containerStack:abolishLock(self.lockReceipt)
        return false
    end
    -- 检查资源是否足够
    if not self.containerStack:isAvailable(self.lockReceipt) then
        self.containerStack:abolishLock(self.lockReceipt)
        return false
    end
    local resourceList = self.containerStack:getResource(self.lockReceipt)
    -- 之前确认过这个票据对应的锁不是空的，所以这里写个注释告知编辑器
    ---@cast resourceList -nil
    for slotOrName, resource in pairs(resourceList) do
        local stepInvoker = invoker()
        -- 是流体
        if type(slotOrName) == "string" then
            stepInvoker:addCommand(fluidCommand(self.containerStack.peripheralName, targetPeripheralName,
                resource.quantity, slotOrName --[[@as string]]))
        else -- 是物品
            stepInvoker:addCommand(itemCommand(self.containerStack.peripheralName, targetPeripheralName,
                slotOrName --[[@as number]],
                resource.quantity))
        end
        -- 如果无法转移至目标容器，result[1]应该是false
        local result = stepInvoker:processAll()
        -- 我去翻了一下相关代码，发现这个值是命令执行后转移的物品总数
        if result[1] ~= resource.quantity then
            errMessage = ("Something wrong happen")
            log.error(errMessage)
            self.containerStack:abolishLock(self.lockReceipt)
            return false
        end
    end
    self.containerStack:abolishLock(self.lockReceipt)
    return true
end

return TransferTicket
