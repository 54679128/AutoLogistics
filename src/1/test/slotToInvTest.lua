require("_steup")

local CommandInvoker = require("CommandInvoker")
local TCSlotToInventory = require("TransferCommand.TCSlotToInventory")

local invoker = CommandInvoker()

-- 测试 1：从 left 槽 1 转移最多 8 个物品到 right 的任意槽
invoker:addCommand(TCSlotToInventory("left", "right", 1, 8))

-- 测试 2：无 limit，转移 left 槽 2 全部物品
invoker:addCommand(TCSlotToInventory("left", "right", 2))

-- 测试 3：limit 为负（应记录错误，按无 limit 处理）
invoker:addCommand(TCSlotToInventory("left", "right", 3, -100))

-- 执行
local results = invoker:processAll()

print("TCSlotToInventory 测试结果:")
print(textutils.serialise(results, { allow_repetitions = true }))

-- 预期：
-- 第一项 ≤8
-- 第二项 = 槽 2 总数
-- 第三项 = 槽 3 总数，且 log.txt 有 error
