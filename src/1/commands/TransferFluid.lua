local base = require("TransferCommandBase")
local log = require("lib.log")

---@param command a546.TransferFluid
---@return number
local function worker(command)
    local sourcePeripheral = peripheral.wrap(command.sourcePeripheralName)
    if not sourcePeripheral then
        return 0
    end
    local result = 0
    local needTransfer = command.limit
    while true do
        local actuallyTransfer = sourcePeripheral.pushFluid(command.targetPeripheralName, needTransfer,
            command.fluidName)
        if command.limit then
            needTransfer = needTransfer - actuallyTransfer
        end
        result = result + actuallyTransfer
        if actuallyTransfer == 0 or needTransfer <= 0 then
            break
        end
    end
    return result
end

---@class a546.TransferFluid:a546.TransferCommandBase
---@field limit number
---@field fluidName string|nil
local TransferFluid = base:extend()

TransferFluid:register("Fluid", worker)

---@cast TransferFluid +fun(source:string, target:string, limit?:number, fluidName?:string):a546.TransferFluid
function TransferFluid:new(source, target, limit, fluidName)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, source, target)
    self.fluidName = fluidName
    self.limit = limit or 5000000
    if self.limit < 0 then
        self.limit = 5000000
        log.warn(("limit must > 0, but get %d"):format(limit))
    end
end

return TransferFluid
