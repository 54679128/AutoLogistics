require("_steup")

local ContainerStack = require("ContainerStack")
local log = require("lib.log")

local function pressEnter()
    print("\npress enter to continue")
    read()
end

-- 测试一：物品容器检测
print("=== Test 1: Item Container Scan ===")
local itemStack = ContainerStack()
local success, err = itemStack:scan("left")
if success then
    print("Item container scan successful")
    print("Container size:", itemStack.size)
    print("Update time:", itemStack.updateTime)

    local allItems = itemStack:getContext()
    print("Number of items:", #allItems)
    for slot, item in pairs(allItems) do
        if type(slot) == "string" then
            goto continue
        end
        print(string.format("  Slot %s: %s x%d", slot, item.name, item.quantity))
        ::continue::
    end
else
    print("Item container scan failed:", err)
end
pressEnter()
-- 测试二：流体容器检测
print("\n=== Test 2: Fluid Container Scan ===")
local fluidStack = ContainerStack()
local success, err = fluidStack:scan("left")
if success then
    print("Fluid container scan successful")
    local allFluids = fluidStack:getContext()
    for name, fluid in pairs(allFluids) do
        if type(name) == "number" then
            goto continue
        end
        print(string.format("  Fluid %s: %s mB", fluid.name, fluid.quantity))
        ::continue::
    end
else
    print("Fluid container scan failed:", err)
end
pressEnter()
-- 测试三：锁定功能
print("\n=== Test 3: Lock Functionality Test ===")
local testStack = ContainerStack()
testStack:scan("left")

-- 锁定单个槽位
print("Locking slot 1")
local lockId1 = testStack:lock(1)
print("Lock ID:", lockId1)

--锁定多个槽位
print("Locking slots 2,3,4")
local lockId2 = testStack:lock({ 2, 3, 4 })
print("Lock ID:", lockId2)

-- 检查锁定状态
local lockItems = testStack:getLock()
local lockCount = 0
for _, _ in pairs(lockItems) do
    lockCount = lockCount + 1
end
print("Number of locked items:", lockCount)
for id, items in pairs(lockItems) do
    local iLockCount = 0
    for _, _ in pairs(items) do
        iLockCount = iLockCount + 1
    end
    print(string.format("  Lock ID %s contains %d items", id, iLockCount))
end

-- 解锁测试
print("Unlocking lock ID:", lockId1)
testStack:unLock(lockId1)
print("Lock status after unlock:")
local remainingLocks = testStack:getLock()
for id, _ in pairs(remainingLocks) do
    print("  Remaining lock ID:", id)
end
pressEnter()
-- 测试四：根据数量锁定
print("\n=== Test 4: Lock by Count ===")
local countStack = ContainerStack()
countStack:scan("left")

-- 假设槽位1、4各有32、16个物品
local lockRequest = {
    { slotOrName = 1, countOrAmount = 32 }, -- 锁定 32 个物品
    { slotOrName = 2, countOrAmount = 16 }  -- 锁定 16 个物品
}

print("Lock by count request:")
for i, req in ipairs(lockRequest) do
    print(string.format("  Slot %d: %d items", req.slotOrName, req.countOrAmount))
end

local countLockId = countStack:lockByCount(lockRequest)
print("Lock ID:", countLockId)

-- 验证剩余数量
local remaining = countStack:getContext()
for slot, item in pairs(remaining) do
    if type(slot) == "string" then
        goto continue
    end
    if item then
        print(string.format("  Slot %d remaining: %s x%d", slot, item.name, item.quantity))
    end
    ::continue::
end
pressEnter()
-- 测试五：保存为文件和重载
print("\n=== Test 5: File Save and Restore ===")
local saveStack = ContainerStack()
saveStack:scan("left")

local saveFile = "container_save.dat"
print("Saving to file:", saveFile)
saveStack:saveAsFile(saveFile)

local restoreStack = ContainerStack()
print("Restoring from file")
restoreStack:reloadFromFile(saveFile)

print("Restored container name:", restoreStack.peripheralName)
print("Restored container size:", restoreStack.size)
print("Restored update time:", restoreStack.updateTime)

-- 清理测试文件
fs.delete(saveFile)
print("Test file cleanup complete")
pressEnter()
-- 测试六：错误处理
print("\n=== Test 6: Error Handling Test ===")

-- 测试锁定不存在的槽位
local errorStack = ContainerStack()
errorStack:scan("left")

print("Attempting to lock non-existent slot 999...")
local status, errMsg = pcall(function()
    errorStack:lock(999)
end)
if not status then
    print("Expected error:", errMsg)
end

-- 尝试使用不存在的票据解锁
print("Attempting to unlock non-existent lock ID...")
local status, errMsg = pcall(function()
    errorStack:unLock("999999")
end)
if not status then
    print("Expected error:", errMsg)
end

print("\n=== All tests completed ===")
print("Check log.txt for detailed log information")
