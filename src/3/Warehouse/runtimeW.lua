local Object = require "lib.Object"
local log    = require "lib.log"


---@class a546.runtimeW
---@field warehouse a546.WarehouseM
---@field interfaces a546.WarehouseInterfaceBase[]
local runtimeW = Object:extend()

---@cast runtimeW +fun(warehouse:a546.WarehouseM):a546.runtimeW
function runtimeW:new(warehouse)
    self.warehouse = warehouse
    self.interfaces = {}
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
