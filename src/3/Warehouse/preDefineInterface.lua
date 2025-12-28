local WarehouseInterface = require "Warehouse.WarehouseInterface"
local ContainerStackM    = require "ContainerStack.ContainerStackM"
local Filter             = require "Filter"


local out = {}

--- 执行后获得一个默认输入接口实例，其会尝试将容器内的所有资源输入仓库
---@param warehouseM a546.WarehouseM
---@param peripheralName string
---@param delay? number # 以毫秒为单位
---@return a546.WarehouseInterface
out.input = function(warehouseM, peripheralName, delay)
    return WarehouseInterface(warehouseM, peripheralName, delay, function()
        warehouseM:input(ContainerStackM(peripheralName), Filter(function()
            return true
        end))
    end)
end

--- 执行后获得一个默认输出接口实例，其会尝试将仓库内的所有资源输出到容器内
---@param warehouseM a546.WarehouseM
---@param peripheralName string
---@param filter? a546.Filter
---@param delay? number # 以毫秒为单位
---@return a546.WarehouseInterface
out.output = function(warehouseM, peripheralName, filter, delay)
    filter = filter or Filter(function() return true end)
    return WarehouseInterface(warehouseM, peripheralName, delay, function()
        warehouseM:output(ContainerStackM(peripheralName), filter)
    end)
end

return out
