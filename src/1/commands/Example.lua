-- 该文件尝试为其它（如果有的话）试图添加新的命令的使用者提供一个示例

local base = require("TransferCommand.TransferCommandBase")

--- 实际执行命令的函数
---@param command CustomPrefix.Example
---@return boolean success # 执行过程中是否有意料外的错误
---@return any result # 函数执行过程中获取的信息
local function worker(command)
    local result
    -- 函数逻辑
    if "Something wrong" then
        return false, nil
    end
    -- 做尽可能少的事，返回尽可能多的信息
    return true, result
end

---@class CustomPrefix.Example:a546.TransferCommandBase
local Example = base:extend()       -- 继承操作，照抄即可

Example:register("Example", worker) -- 第一个参数随意，但最好不要与已有的命令相同；第二个参数填上面你写好的函数。函数名可以是无意义的，反正也不会在别的地方用到

-- 下面的 @cast 用于为 Example 变量（类）添加函数类型，你可以不加。但加上可以方便其他人（如果有的话）理解，且可以提供编辑器内提示。
-- 使用 instance = Example(...) 获取一个 Example 的实例。如果你想知道为什么可以这么做，查看 "src\lib\Object.lua"
---@cast Example +fun(firstParam:any):CustomPrefix.Example
function Example:new(firstParam, ...)
    ---@diagnostic disable-next-line: redundant-parameter
    self.super.new(self, ...) -- 照抄，想了解细节去看 "src\lib\Object.lua"

    -- 设置该命令需要什么参数，并将这些参数存储到你指定的地方
    -- 这些参数可以在最上面的函数内部使用
    self.firstParam = firstParam
end

return Example
