local InterfaceBase   = require "Warehouse.WarehouseInterface.InterfaceBase"
local ContainerStackM = require "ContainerStack.ContainerStackM"
local Filter          = require "Filter"

---@class a546.WarehouseInputInterface:a546.WarehouseInterfaceBase
local input           = InterfaceBase:extend()

---@cast input +fun(warehouseM:a546.WarehouseM):a546.WarehouseInputInterface
function input:new(warehouseM, peripheralName)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, warehouseM, peripheralName, 3)
end

function input:mayer()
    self.warehouse:input(ContainerStackM(self.peripheralName), Filter(function(resource)
        return true
    end))
end

return input
