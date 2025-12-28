local Object = require "lib.Object"
local log    = require "lib.log"


---@class a546.runtimeW
---@field warehouse a546.WarehouseM
---@field interfaces table<string,a546.WarehouseInterface>
local runtimeW = Object:extend()

---@cast runtimeW +fun(warehouse:a546.WarehouseM):a546.runtimeW
function runtimeW:new(warehouse)
    self.warehouse = warehouse
    self.interfaces = {}
end

--- 添加一个接口
---@param interface a546.WarehouseInterface
---@return boolean
function runtimeW:addInterface(interface)
    if not interface or not interface.peripheralName then
        log.error(("Expect a WarehouseInterface but get something else"))
        return false
    end
    self.interfaces[interface.peripheralName] = interface
    return true
end

--- 移除一个接口
---@param peripheralName string
---@return boolean
function runtimeW:removeInterface(peripheralName)
    if not peripheralName then
        return false
    end
    if not self.interfaces[peripheralName] then
        return false
    end
    self.interfaces[peripheralName] = nil
    return true
end

function runtimeW:run()
    if not self.warehouse then
        log.warn(("Try to run without warehouse"))
        return
    end
    local exTime = {}
    for index, interface in pairs(self.interfaces) do
        exTime[index] = os.epoch("local")
    end
    while true do
        while true do
            local mark = os.startTimer(0.1)
            local data = { os.pullEvent("timer") }
            if data[2] == mark then
                break
            end
        end
        self.warehouse:randomRefresh()
        for index, lastTime in pairs(exTime) do
            if os.epoch("local") - lastTime >= self.interfaces[index].delay then
                self.interfaces[index].mayer()
            end
        end
    end
end

return runtimeW
