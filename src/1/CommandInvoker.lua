local Object = require("lib.Object")
local log = require("lib.log")
log.outfile = "log.txt"
log.usecolor = false

---@class a546.CommandInvoker
---@field commands a546.TransferCommandBase[]
local CommandInvoker = Object:extend()

---@cast CommandInvoker +fun():a546.CommandInvoker
function CommandInvoker:new()
    self.commands = {}
end

--- 向指令组中添加指令
---@param command a546.TransferCommandBase
function CommandInvoker:addCommand(command)
    table.insert(self.commands, command)
end

-- 清除所有指令
function CommandInvoker:clear()
    self.commands = {}
end

--- 执行所有命令
---@return table<number,TransferResult>
function CommandInvoker:processAll()
    local result = {}
    for _, command in ipairs(self.commands) do
        local handler = command.handler
        if not handler then
            -- 找到或自己写了一个日志模块后这里加上相应日志代码
            -- error(("command %s does't exists"):format(command.commandType))
            log.error(("command %s does't exists"):format(command.commandType))
        end
        ---@alias TransferResult {transferResource:number,errMessage:nil|string}
        local resultFormat = {
            transferResource = 0,
            errMessage = nil
        }
        ---@type [boolean,number]|[boolean,string,number]
        local k = table.pack(pcall(handler, command))
        if not k[1] then
            -- 找到或自己写了一个日志模块后这里加上相应日志代码
            --print(("Command %s execution failed"):format(command.commandType))
            --print(("error message: %s"):format(tostring(k[2])))
            resultFormat.errMessage = k[2]
            resultFormat.transferResource = k[3]
            log.warn(("Command %s execution failed: %s"):format(command.commandType, tostring(k[2])))
        else
            log.trace(("Command %s success"):format(command.commandType))
            resultFormat.transferResource = k[2]
        end
        table.insert(result, resultFormat)
    end
    return result
end

return CommandInvoker
