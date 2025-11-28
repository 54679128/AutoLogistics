require("_stesuo")
print(package.path)
sleep(5)
local invoke = require("CommandInvoker")
print("success get invoke")
local command = require("TransferCommand.TCItemInventory")
print("success get command")
-- 测试环境：将src文件夹复制到目标计算机，在运行该测试的计算机或海龟两侧放置大小相等的容器，初始时左侧容器放置若干物品

local testInvoke = invoke:new()

testInvoke:addCommand(command("left", "right"))
testInvoke:addCommand(command("right", "left"))
testInvoke:processAll()
