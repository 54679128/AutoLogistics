local Object = require("lib.Object")
local log = require("lib.log")

---@class a546.TicketBundle
---@field private tickets table<Receipt,a546.TransferTicketM>
---@field private usage boolean
local TicketBundle = Object:extend()

---@cast TicketBundle +fun():a546.TicketBundle
function TicketBundle:new()
    self.tickets = {}
    self.usage = false
end

--- 添加一张支票
---@param receipt Receipt
---@param ticket a546.TransferTicketM
function TicketBundle:add(receipt, ticket)
    log.trace(("Add ticket %s / %s to ticketBundle %s"):format(tostring(ticket), receipt, tostring(self)))
    self.tickets[receipt] = ticket
end

--- 尝试移除一张支票
---@param receipt Receipt
---@return a546.TransferTicketM|nil
function TicketBundle:remove(receipt)
    local result = self.tickets[receipt]
    self.tickets[receipt] = nil
    log.trace(("Remove ticket %s from ticketBundle %s"):format(receipt, tostring(self)))
    return result
end

--- 尝试依次使用所有支票
---@param targetPeripheralName string
---@return boolean
function TicketBundle:run(targetPeripheralName)
    if self.usage then
        return false
    end
    for _, ticket in pairs(self.tickets) do
        local success = ticket:use(targetPeripheralName)
        log.trace(("Ticket %s successful use"):format(tostring(ticket)))
        if not success then
            log.trace(("Ticket %s fail when use"):format(tostring(ticket)))
            self.usage = true
        end
    end
    self.usage = true
    return true
end

return TicketBundle
