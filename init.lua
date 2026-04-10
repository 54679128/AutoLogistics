local out = {}
local originRequire = require
local parentModuleName = (({ ... })[1]) --:gsub("\\[^\\]+$", "")
--print(("父模块路径：%s"):format(parentModuleName))
local function modifiedRequire(moduleName)
    local modifiedModuleName = ("%s.%s.%s"):format(parentModuleName, "src", moduleName)
    -- print(("修改后的模块名为：%s"):format(modifiedModuleName))
    return originRequire(modifiedModuleName)
end

--- 加载子模块
---@param moduleName string
local function loadModule(moduleName)
    local moduleActuallyName = moduleName:match("%.?([^%.]+)$")
    -- print(("实际模块名为：%s"):format(moduleActuallyName))
    out[moduleActuallyName] = require(moduleName)
    --print(("成功加载 \"%s\" 模块"):format(moduleActuallyName))
end

require = modifiedRequire
-- print(("成功替换 require 函数"))

-- 加载第一层模块
loadModule("1.CommandInvoker")
loadModule("1.commands.TransferFluid")
loadModule("1.commands.TransferItems")
loadModule("1.commands.TransferSlotToInventory")
loadModule("1.commands.TransferSlotToSlot")
-- 加载第二层模块
loadModule("2.Filter")
loadModule("2.preDefinedFilter")
loadModule("2.ContainerStack.ContainerScan")
loadModule("2.ContainerStack.ContainerStackM")
loadModule("2.ContainerStack.ResourceManager")
loadModule("2.ContainerStack.TransferTicketM")
-- 目前正在考虑是否将第三层移除出该模块并将其作为一个独立应用实现，所以不导出

require = originRequire
-- print(("成功恢复 require 函数"));
return out
