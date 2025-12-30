local WarehouseInterface = require "Warehouse.WarehouseInterface"
local ContainerStackM    = require "ContainerStack.ContainerStackM"
local Filter             = require "Filter"
local log                = require "lib.log"


local out = {}

--- 执行后获得一个默认输入接口实例，其会尝试将容器内的所有资源输入仓库
---@param warehouseM a546.WarehouseM
---@param peripheralName string
---@param delay? number # 以毫秒为单位
---@return a546.WarehouseInterface
out.input = function(warehouseM, peripheralName, delay)
    delay = delay or 3000
    return WarehouseInterface(warehouseM, peripheralName, delay, function()
        log.trace(("Start to input"))
        local container = ContainerStackM(peripheralName)
        container:refresh()
        warehouseM:input(container, Filter(function()
            return true
        end))
        log.trace(("Input end"))
    end, ("Input: %s"):format(peripheralName))
end

--- 执行后获得一个默认输出接口实例，其会尝试将仓库内的所有资源输出到容器内
---@param warehouseM a546.WarehouseM
---@param peripheralName string
---@param filter? a546.Filter
---@param delay? number # 以毫秒为单位
---@return a546.WarehouseInterface
out.output = function(warehouseM, peripheralName, filter, delay)
    delay = delay or 3000
    filter = filter or Filter(function() return true end)
    return WarehouseInterface(warehouseM, peripheralName, delay, function()
        log.trace(("Start to output"))
        warehouseM:output(ContainerStackM(peripheralName), filter)
        log.trace(("Output end"))
    end, ("Output: %s"):format(peripheralName))
end

return out
