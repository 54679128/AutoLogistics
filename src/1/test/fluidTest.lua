require("_steup")

local invoke = require("CommandInvoker")
local command = require("commands.TransferFluid")
-- 测试环境：将src文件夹复制到目标计算机，在运行该测试的计算机或海龟两侧放置流体容器，初始时向左侧容器注入适当流体
-- 注意事项：保证容器没有某种访问限制

local testInvoke = invoke()
testInvoke:addCommand(command("left", "right", 600))
testInvoke:addCommand(command("right", "left"))
testInvoke:addCommand(command("left", "right", -600))
testInvoke:addCommand(command("right", "left"))

-- 预期输出：{600,600,max,max}
--         日志中应该有报错
print(textutils.serialise(testInvoke:processAll(), { allow_repetitions = true }))
