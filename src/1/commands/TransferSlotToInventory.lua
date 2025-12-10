local base = require("TransferCommandBase")
local log = require("lib.log")

---@param command a546.TransferSlotToInventory
---@return number
local function worker(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return 0
    end
    local result = 0
    local needTransfer = command.limit
    while true do
        local actuallyTransfer = sourcePeripheral.pushItems(command.targetPeripheralName, command.sourceSlot,
            needTransfer)
        if command.limit then
            needTransfer = needTransfer - actuallyTransfer
        end
        result = result + actuallyTransfer
        if actuallyTransfer == 0 then
            break
        end
        if needTransfer and needTransfer < 0 then
            break
        end
    end
    return result
end

---@class a546.TransferSlotToInventory:a546.TransferCommandBase
---@field sourceSlot number
---@field limit number|nil
local TransferSlotToInventory = base:extend()

TransferSlotToInventory:register("SlotToInventory", worker)


---@cast TransferSlotToInventory +fun(sourcePeripheralName:string, targetPeripheralName:string, sourceSlot:number, limit?:number):a546.TransferSlotToInventory
function TransferSlotToInventory:new(sourcePeripheralName, targetPeripheralName, sourceSlot, limit)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, sourcePeripheralName, targetPeripheralName)
    self.sourceSlot = sourceSlot
    self.limit = limit
    if limit and limit < 0 then
        self.limit = nil
        log.warn(("limit must > 0 or nil,but get %d"):format(limit))
    end
end

return TransferSlotToInventory
