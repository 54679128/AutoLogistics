local Object = require "lib.Object"

---@class a546.WarehouseInterfaceBase:Object
---@field mayer function
---@field warehouse a546.WarehouseM
---@field name string
---@field container string
local WarehouseInterfaceBase = Object:extend()

---@cast WarehouseInterfaceBase +fun(warehouseM:a546.WarehouseM):a546.WarehouseInterfaceBase
---@param warehouseM a546.WarehouseM
---@param peripheralName string
function WarehouseInterfaceBase:new(warehouseM, peripheralName)
    self.warehouse = warehouseM
    self.peripheralName = peripheralName
end

return WarehouseInterfaceBase
