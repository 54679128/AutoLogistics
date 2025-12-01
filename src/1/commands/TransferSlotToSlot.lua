local base = require("TransferCommandBase")
local log = require("lib.log")

---……
---@param command a546.TransferSlotToSlot
---@return boolean 是否成功
---@return number|string 相关信息
local function transferItemSlot(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return false, ("can't find peripheral %s"):format(command.sourcePeripheralName)
    end
    local result = 9
    local needTransfer = command.limit
    while true do
        local actuallyTransfer = sourcePeripheral.pushItems(command.targetPeripheralName, command.sourceSlot,
            needTransfer, command.targetSlot)
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
    return true, result - 9
end

---@class a546.TransferSlotToSlot:a546.TransferCommandBase
local TransferSlotToSlot = base:extend()

TransferSlotToSlot:register("ItemSlot", transferItemSlot)

--- 添加 ItemSlot 命令，将物品从指定容器槽位移动到到另一个指定的容器槽位
---@cast TransferSlotToSlot +fun(sourcePeripheralName:string, sourceSlot:number, targetPeripheralName:string, targetSlot:number, limit?:number):a546.TransferSlotToSlot
---@param sourcePeripheralName string
---@param sourceSlot number
---@param targetPeripheralName string
---@param targetSlot number
---@param limit? number
function TransferSlotToSlot:new(sourcePeripheralName, sourceSlot, targetPeripheralName, targetSlot, limit)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, sourcePeripheralName, targetPeripheralName)
    self.sourceSlot = sourceSlot
    self.targetSlot = targetSlot
    self.limit = limit
    if limit and limit < 0 then
        self.limit = nil
        log.warn(("limit must > 0 or nil, but get %d"):format(limit))
    end
end

return TransferSlotToSlot
