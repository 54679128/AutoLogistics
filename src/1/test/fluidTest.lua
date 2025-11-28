require("_steup")

local invoke = require("CommandInvoker")
local command = require("TransferCommand.TCFluid")
-- 测试环境：将src文件夹复制到目标计算机，在运行该测试的计算机或海龟两侧放置流体容器，初始时向左侧容器注入适当流体
-- 注意事项：保证容器没有某种访问限制

local testInvoke = invoke:new()
testInvoke:addCommand(command("left", "right"))
testInvoke:addCommand(command("right", "left"))

print(textutils.serialise(testInvoke:processAll(), { allow_repetitions = true }))
