local base = require("TransferCommandBase")

---@param command a546.TCSlotToInventory
---@return boolean 是否成功
---@return number|string 相关信息
local function worker(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return false, ("can't find peripheral %s"):format(command.sourcePeripheralName)
    end
    local result = 0
    while true do
        local actuallyTransfer = sourcePeripheral.pushItems(command.targetPeripheralName, command.sourceSlot,
            command.limit)
        result = result + actuallyTransfer
        if actuallyTransfer == 0 then
            break
        end
    end
    return true, result
end

---@class a546.TCSlotToInventory:a546.TransferCommandBase
---@field sourceSlot number
---@field limit number|nil
local TCSlotToInventory = base:extend()

TCSlotToInventory:register("SlotToInventory", worker)


---@cast TCSlotToInventory +fun(sourcePeripheralName:string, sourceSlot:number, targetPeripheralName:number, limit?:number):a546.TCSlotToInventory
function TCSlotToInventory:new(sourcePeripheralName, sourceSlot, targetPeripheralName, limit)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, sourcePeripheralName, targetPeripheralName)
    self.limit = limit
end

return TCSlotToInventory
