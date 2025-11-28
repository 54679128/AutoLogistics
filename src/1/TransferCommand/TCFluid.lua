local base = require("TransferCommand.TransferCommandBase")

---@param command a546.TCFluid
---@return boolean
---@return number|string
local function worker(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return false, ("can't find peripheral %s"):format(command.sourcePeripheralName)
    end
    local result = 0
    while true do
        local actuallyTransfer = sourcePeripheral.pushFluid(command.targetPeripheralName, command.limit,
            command.fluidName)
        result = result + actuallyTransfer
        if actuallyTransfer == 0 then
            break
        end
    end
    return true, result
end

---@class a546.TCFluid:a546.TransferCommandBase
---@field limit number|nil
---@field fluidName string|nil
local TCFluid = base:extend()

TCFluid:register("Fluid", worker)

---@cast TCFluid +fun(source:string, target:string, name:string, limit?:number):a546.TCFluid
function TCFluid:new(source, target, name, limit)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, source, target)
    self.name = name
    self.limit = limit
end

return TCFluid
