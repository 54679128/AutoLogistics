local out = {}
local parentModuleName = (({ ... })[1]):gsub("\\[^\\]+$", "")
local oldPath = package.path
package.path = package.path .. ("%s\\src\\?.lua;"):format(parentModuleName)
print(("修改后的 package.path 为：%s"):format(package.path))

--- 加载子模块
---@param moduleName string
local function loadModule(moduleName)
    local moduleActuallyName = moduleName:match("%.([^%.]+)$")
    print(("实际模块名为：%s"):format(moduleActuallyName))
    out[moduleActuallyName] = require(moduleName)
    print(("成功加载 \"%s\" 模块"):format(moduleActuallyName))
end

-- 加载第一层模块
loadModule("1.CommandInvoker")
loadModule("1.commands.TransferFluid")
loadModule("1.commands.TransferItems")
loadModule("1.commands.TransferSlotToInventory")
loadModule("1.commands.TransferSlotToSlot")
-- 加载第二层模块
loadModule("2.Filter")
loadModule("2.preDefinedFilter")

-- 恢复原来的模块查找路径（不恢复也行，但这样做我看起来舒服一些）
package.path = oldPath
return out
