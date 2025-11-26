-- 这是一个接口模块

---@class a546.CommandInvoker
---@field commands a546.TransferCommand[]|a546.TransferCommandBase[]
local CommandInvoker = {
    commands = {}
}

--- 向指令组中添加指令
---@param command a546.TransferCommand|a546.TransferCommandBase
function CommandInvoker:addCommand(command)
    table.insert(self.commands, command)
end

---@return a546.CommandInvoker
function CommandInvoker:new(o)
    o = o or { commands = {} }
    self.__index = self
    setmetatable(o, self)
    return o
end

-- 清除所有指令
function CommandInvoker:clear()
    self.commands = {}
end

function CommandInvoker:processAll()
    for _, command in ipairs(self.commands) do
        local handler = command.handler
        if not handler then
            -- 找到或自己写了一个日志模块后这里加上相应日志代码
            error(("command %s does't exists"):format(command.commandType))
        end
        local ok, err = pcall(handler, command)
        if not ok then
            -- 找到或自己写了一个日志模块后这里加上相应日志代码
            print(("Command %s execution failed"):format(command.commandType))
            print(("error message: %s"):format(tostring(err)))
        end
    end
end

return CommandInvoker
