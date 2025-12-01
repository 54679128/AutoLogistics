local Object = require "lib.Object"

---@class a546.TransferCommandBase:Object
---@field commandType string 指令种类
---@field handler function 回调函数
---@field sourcePeripheralName string 源外设名
---@field targetPeripheralName string 目标外设名
local TransferCommandBase = Object:extend()

--- 注册类型和回调函数
---@param commandType string
---@param handler function
function TransferCommandBase:register(commandType, handler)
    self.commandType = commandType
    self.handler = handler
    self.__tostring = function(v)
        ---@diagnostic disable-next-line: undefined-field
        return v.commandType
    end
end

---@param sourcePeripheralName string
---@param targetPeripheralName string
function TransferCommandBase:new(sourcePeripheralName, targetPeripheralName)
    self.sourcePeripheralName = sourcePeripheralName
    self.targetPeripheralName = targetPeripheralName
end

return TransferCommandBase

-- 之后的命令类将以"TC***"命名

-- 做尽可能少的事，返回尽可能多的信息
