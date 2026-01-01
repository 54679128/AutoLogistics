local Object = require("lib.Object")
local log = require("lib.log")
local util = require("lib.util")

---@class a546.TicketBundle
---@field private tickets table<Receipt,a546.TransferTicketM>
---@field private usage boolean
---@field name string
local TicketBundle = Object:extend()

---@cast TicketBundle +fun(name?:string):a546.TicketBundle
function TicketBundle:new(name)
    self.tickets = {}
    self.usage = false
    self.name = name or util.generateRandomString(4)
end

function TicketBundle:__tostring()
    return self.name
end

--- 添加一张支票
---@param receipt Receipt
---@param ticket a546.TransferTicketM
function TicketBundle:add(receipt, ticket)
    log.trace(("Add ticket %s to ticketBundle %s"):format(ticket, self))
    self.tickets[receipt] = ticket
end

--- 尝试移除一张支票
---@param receipt Receipt
---@return a546.TransferTicketM|nil
function TicketBundle:remove(receipt)
    local result = self.tickets[receipt]
    self.tickets[receipt] = nil
    log.trace(("Remove ticket %s from ticketBundle %s"):format(result, self))
    return result
end

--- 尝试依次使用所有支票
---@param targetPeripheralName string
---@return boolean
function TicketBundle:run(targetPeripheralName)
    if self.usage then
        return false
    end
    self.usage = true
    for _, ticket in pairs(self.tickets) do
        local success = ticket:use(targetPeripheralName)
        if not success then
            log.trace(("Ticket %s fail when use"):format(ticket))
        else
            log.trace(("Ticket %s successful use"):format(ticket))
        end
    end
    return true
end

return TicketBundle
