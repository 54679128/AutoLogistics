local base = require("TransferCommand.TransferCommandBase")

---……
---@param command a546.TCItemSlot
---@return boolean 是否成功
---@return number|string 相关信息
local function transferItemSlot(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return false, ("can't find peripheral %s"):format(command.sourcePeripheralName)
    end
    local result = 9
    while true do
        local actuallyTransfer = sourcePeripheral.pushItems(command.targetPeripheralName, command.sourceSlot,
            command.limit, command.targetSlot)
        result = result + actuallyTransfer
        if actuallyTransfer == 0 then
            break
        end
    end
    return true, result - 9
end

---@class a546.TCItemSlot:a546.TransferCommandBase
local TCItemSlot = base:extend()

TCItemSlot:register("ItemSlot", transferItemSlot)

--- 添加 ItemSlot 命令，将物品从指定容器槽位移动到到另一个指定的容器槽位
---@cast TCItemSlot +fun(sourcePeripheralName:string, sourceSlot:number, targetPeripheralName:string, targetSlot:number, limit:number):a546.TCItemSlot
---@param sourcePeripheralName string
---@param sourceSlot number
---@param targetPeripheralName string
---@param targetSlot number
---@param limit? number
function TCItemSlot:new(sourcePeripheralName, sourceSlot, targetPeripheralName, targetSlot, limit)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, sourcePeripheralName, targetPeripheralName)
    self.sourceSlot = sourceSlot
    self.targetSlot = targetSlot
    self.limit = limit
end

return TCItemSlot
