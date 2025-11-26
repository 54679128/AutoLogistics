local base = require("TransferCommandBase")

---@param command a546.TCItemInventory
---@return boolean success # 执行过程中是否有意料外的错误
---@return number|string result # 函数执行过程中获取的信息
local function transferItemInventory(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return false, ("can't find peripheral %s"):format(command.sourcePeripheralName)
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
    return true, result
end

---@class a546.TCItemInventory:a546.TransferCommandBase
local TCItemInventory = base:extend()

TCItemInventory:register("ItemInventory", transferItemInventory)

---@cast TCItemInventory +fun(sourcePeripheralName:string,targetPeripheralName:string):a546.TCItemInventory
---@param sourcePeripheralName string
---@param targetPeripheralName string
function TCItemInventory:new(sourcePeripheralName, targetPeripheralName)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, sourcePeripheralName, targetPeripheralName)
end

return TCItemInventory
