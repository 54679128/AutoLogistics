require("_stesuo")

local invoke = require("CommandInvoker")
local command = require("TransferCommand.TCItemInventory")
-- 测试环境：将src文件夹复制到目标计算机，在运行该测试的计算机或海龟两侧放置大小相等的容器，初始时左侧容器放置若干物品

local testInvoke = invoke:new()

testInvoke:addCommand(command("left", "top"))
testInvoke:addCommand(command("top", "right"))
testInvoke:addCommand(command("right", "bottom"))
testInvoke:addCommand(command("bottom", "left"))
while true do
    testInvoke:processAll()
end
