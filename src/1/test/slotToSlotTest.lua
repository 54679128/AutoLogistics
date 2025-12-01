require("_steup")

local CommandInvoker = require("CommandInvoker")
local TCItemSlot = require("commands.TransferSlotToSlot")

-- 创建命令执行器
local invoker = CommandInvoker()

-- 测试 1：正常转移（从 left 槽 1 → right 槽 3，最多 10 个）
invoker:addCommand(TCItemSlot("left", 1, "right", 3, 10))

-- 测试 2：无 limit（全部转移）
invoker:addCommand(TCItemSlot("left", 2, "right", 4))

-- 测试 3：limit 为负数（应触发日志错误，并当作无 limit 处理）
invoker:addCommand(TCItemSlot("left", 3, "right", 5, -5))

-- 执行所有命令
local results = invoker:processAll()

-- 输出结果
print("TCItemSlot test result:")
print(textutils.serialise(results, { allow_repetitions = true }))

-- 预期：
-- 第一个命令返回 ≤10 的实际转移数
-- 第二个返回该槽全部物品数
-- 第三个应等同于无 limit，并在 log.txt 中有 error 记录
