local Object = require "lib.Object"

---@class a546.WarehouseInterfaceBase:Object
---@field mayer function
---@field warehouse a546.WarehouseM
---@field name string
---@field container string
---@field delay number 两次运行mayer函数的最小时间间隔，以毫秒为单位
local WarehouseInterfaceBase = Object:extend()

---@cast WarehouseInterfaceBase +fun(warehouseM:a546.WarehouseM,peripheralName:string,delay:number):a546.WarehouseInterfaceBase
---@param warehouseM a546.WarehouseM
---@param peripheralName string
function WarehouseInterfaceBase:new(warehouseM, peripheralName, delay)
    self.warehouse = warehouseM
    self.peripheralName = peripheralName
    self.delay = delay
end

return WarehouseInterfaceBase
