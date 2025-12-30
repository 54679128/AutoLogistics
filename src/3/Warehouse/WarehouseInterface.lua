local Object = require "lib.Object"

---@class a546.WarehouseInterface:Object
---@field mayer function
---@field warehouse a546.WarehouseM
---@field name string
---@field container string
---@field delay number 两次运行mayer函数的最小时间间隔，以毫秒为单位
local WarehouseInterface = Object:extend()

---@cast WarehouseInterface +fun(warehouseM:a546.WarehouseM,peripheralName:string,delay?:number,mayer?:function,name?:string):a546.WarehouseInterface
---@param warehouseM a546.WarehouseM
---@param peripheralName string
function WarehouseInterface:new(warehouseM, peripheralName, delay, mayer, name)
    self.warehouse = warehouseM
    self.peripheralName = peripheralName
    self.delay = delay or 3000
    self.mayer = mayer or function()
        return false
    end
    self.name = name or peripheralName
end

return WarehouseInterface
