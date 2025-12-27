local InterfaceBase   = require "Warehouse.WarehouseInterface.InterfaceBase"
local ContainerStackM = require "ContainerStack.ContainerStackM"
local Filter          = require "Filter"

---@class a546.WarehouseOutputInterface:a546.WarehouseInterfaceBase
local output          = InterfaceBase:extend()

---@cast output +fun(warehouseM:a546.WarehouseM):a546.WarehouseOutputInterface
function output:new(warehouseM, peripheralName)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, warehouseM, peripheralName, 3)
end

function output:mayer()
    self.warehouse:output(ContainerStackM(self.peripheralName), Filter(function(resource)
        return true
    end))
end

return output
