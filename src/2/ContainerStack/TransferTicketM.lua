local log = require("lib.log")
local Object = require("lib.Object")
local itemCommand = require("commands.TransferSlotToInventory")
local fluidCommand = require("commands.TransferFluid")
local invoker = require("CommandInvoker")

local expirationTime = 5

---@alias LockReceipt string # 票据

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

function TransferTicketM:__tostring()
    return self.receipt .. tostring(self.createdAt)
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
    self.used = true
    if not self:isAvailable() then
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
            log.warn(("The actual transfer quantity: %s isn't equal to the scheduled transfer quantity: %s"):format(
                tostring(transferQuantityResult[1].transferResource), tostring(info.quantity)))
            if transferQuantityResult[1].errMessage then  -- 如果确实发生了某种错误（比如外设源、目标任一外设消失）而不是传输数量与预期不符，那么没有任何方法确定具体传输了多少物品
                log.error(transferQuantityResult[1].errMessage)
                self.containerStack:consume(self.receipt) -- 另外这里还有一个问题：想象一个`receipt`对应着成千上万槽位的不同资源，贸然删除它们会带来奇怪的后果。
            else                                          -- 在这里，我们明确一次传输实际上传输了多少资源，并只消耗对应数量的资源
                log.debug(("No error message, Consume part of resource: %s"):format(tostring(transferQuantityResult[1]
                    .transferResource)))
                self.containerStack:consume(self.receipt,
                    { slotOrName = slotOrName, quantity = transferQuantityResult[1].transferResource })
            end
            return false
        end
        stepInvoker:clear()
    end

    self.containerStack:release(self.receipt) -- 最后，释放那些实际上没有用到的资源
    return true
end

return TransferTicketM
