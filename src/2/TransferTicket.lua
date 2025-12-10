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
    -- 考虑目标容器是一台机器，我不认为`ContainerStack`可以很好的描述一台运行中的机器——但确实，可以这么做——所以我确定使用目标外设名作为参数。

    self.run = true
    local function cleanup()
        self.containerStack:abolishLock(self.lockReceipt)
    end
    local errMessage
    -- 检查容器是否存在
    local source = peripheral.wrap(self.containerStack.peripheralName)
    if not source then
        errMessage = ("Peripheral %s doesn't exist"):format(self.containerStack.peripheralName)
        log.error(errMessage)
        cleanup()
        return false
    end
    -- 检查资源是否足够
    if not self.containerStack:isAvailable(self.lockReceipt) then
        cleanup()
        return false
    end
    local resourceList = self.containerStack:getResource(self.lockReceipt)
    -- 之前确认过这个票据对应的锁不是空的，所以这里写个注释告知编辑器
    ---@cast resourceList -nil
    for slotOrName, resource in pairs(resourceList) do
        local stepInvoker = invoker()
        -- 下面将构造并插入命令
        -- 是流体
        if type(slotOrName) == "string" then
            stepInvoker:addCommand(fluidCommand(self.containerStack.peripheralName, targetPeripheralName,
                resource.quantity, slotOrName --[[@as string]]))
        else -- 是物品
            stepInvoker:addCommand(itemCommand(self.containerStack.peripheralName, targetPeripheralName,
                slotOrName --[[@as number]],
                resource.quantity))
        end
        -- 执行命令并检查是否转移了足够的物品
        local result = stepInvoker:processAll()
        -- 如果转移到的容器是一台正在运行的机器，原料可能被瞬间处理、被锁在输入槽，总之没法拿回来，只能简单的中止传输并报错
        -- 因为只放了一条命令，所以这里填 1
        if resource.quantity ~= result[1].transferResource then
            cleanup()
            return false
        end
        stepInvoker:clear()
    end
    cleanup()
    return true
end

return TransferTicket
