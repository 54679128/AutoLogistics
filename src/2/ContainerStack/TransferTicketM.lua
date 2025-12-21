local log = require("lib.log")
local Object = require("lib.Object")
local itemCommand = require("commands.TransferSlotToInventory")
local fluidCommand = require("commands.TransferFluid")
local invoker = require("CommandInvoker")

local expirationTime = 5

---@class a546.TransferTicketM
---@field private containerStack a546.ContainerStackM
---@field private receipt LockReceipt
---@field private used boolean
local TransferTicketM = Object:extend()

---@cast TransferTicketM +fun(containerStack:a546.ContainerStackM,receipt:Receipt):a546.TransferTicketM
function TransferTicketM:new(containerStack, receipt)
    self.containerStack = containerStack
    self.receipt = receipt
    self.createdAt = os.epoch("local")
    self.used = false
end

--- 检查支票是否可用
---@return boolean
function TransferTicketM:isAvailable()
    if not self.containerStack:isAvailable(self.receipt) then
        return false
    end
    if os.epoch("local") - self.createdAt > expirationTime * 1000 then
        return false
    end
    if self.used then
        return false
    end
    return true
end

--- 使用支票。无论是否成功，该支票无法再次使用
---@param targetPeripheralName string
---@return boolean
function TransferTicketM:use(targetPeripheralName)
    local function cleanup()
        self.used = true
    end
    if not self:isAvailable() then
        cleanup()
        self.containerStack:release(self.receipt)
        return false
    end
    -- 已验证票据可用，所以reserve必不为nil
    local reserve = self.containerStack:getReserve(self.receipt)
    local stepInvoker = invoker()
    ---@cast reserve -nil
    for slotOrName, info in pairs(reserve) do
        if type(slotOrName) == "string" then
            stepInvoker:addCommand(fluidCommand(self.containerStack.peripheralName, targetPeripheralName, info.quantity,
                info.name))
        else
            stepInvoker:addCommand(itemCommand(self.containerStack.peripheralName, targetPeripheralName, slotOrName,
                info.quantity))
        end
        local transferQuantityResult = stepInvoker:processAll()
        if transferQuantityResult[1].transferResource ~= info.quantity then
            cleanup()
            self.containerStack:consume(self.receipt)
            log.error(transferQuantityResult[1].errMessage)
            return false
        end
        stepInvoker:clear()
    end
    cleanup()
    self.containerStack:consume(self.receipt)
    return true
end

return TransferTicketM
