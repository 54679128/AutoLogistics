require("_steup")

local invoke = require("CommandInvoker")
local command = require("TransferCommand.TCItemInventory")
-- 测试环境：将src文件夹复制到目标计算机，在运行该测试的计算机或海龟两侧放置物品容器，初始时左侧容器放置若干物品

local testInvoke = invoke:new()

testInvoke:addCommand(command("left", "right"))

testInvoke:addCommand(command("right", "left"))

local result = testInvoke:processAll()

-- 该程序会打印两次转移物品的数量。如果两侧容器均可完全容纳最初放置的物品，这两个值应该相等
print(textutils.serialise(result, { allow_repetitions = true }))
