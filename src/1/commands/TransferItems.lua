local base = require("TransferCommandBase")

---@param command a546.TransferItems
---@return number
local function transferItemInventory(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return 0
    end
    local result = 0
    local itemList = sourcePeripheral.list()
    for slot, _ in pairs(itemList) do
        while true do
            local actuallyTransfer = sourcePeripheral.pushItems(command.targetPeripheralName, slot)
            result = result + actuallyTransfer
            if actuallyTransfer == 0 then
                break
            end
        end
    end
    return result
end

---@class a546.TransferItems:a546.TransferCommandBase
local TransferItems = base:extend()

TransferItems:register("ItemInventory", transferItemInventory)

---@cast TransferItems +fun(sourcePeripheralName:string,targetPeripheralName:string):a546.TransferItems
---@param sourcePeripheralName string
---@param targetPeripheralName string
function TransferItems:new(sourcePeripheralName, targetPeripheralName)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, sourcePeripheralName, targetPeripheralName)
end

return TransferItems
