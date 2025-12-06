require("_steup")

local ContainerStack = require("ContainerStack")
local log = require("lib.log")

local function pressEnter()
    print("\npress enter to continue")
    read()
end

-- Test 1: 物品检测
log.info("=== Test 1: Item Container Scan ===")
local itemStack = ContainerStack()
local success, err = itemStack:scan("left")
if success then
    log.info("Item container scan successful")
    log.info("Container size:", itemStack.size)
    log.info("Update time:", itemStack.updateTime)

    local allItems = itemStack:getContext()
    log.info("Number of items:", #allItems)
    for slot, item in pairs(allItems) do
        if type(slot) == "string" then
            goto continue
        end
        log.info(string.format("  Slot %s: %s x%d", slot, item.name, item.count))
        ::continue::
    end
else
    log.error("Item container scan failed:", err)
end
pressEnter()

-- Test 2: 流体探测
log.info("\n=== Test 2: Fluid Container Scan ===")
local fluidStack = ContainerStack()
local success, err = fluidStack:scan("left")
if success then
    log.info("Fluid container scan successful")
    local allFluids = fluidStack:getContext()
    for name, fluid in pairs(allFluids) do
        if type(name) == "number" then
            goto continue
        end
        log.info(string.format("  Fluid %s: %s mB", fluid.name, fluid.count))
        ::continue::
    end
else
    log.error("Fluid container scan failed:", err)
end
pressEnter()

-- 测试 3: 锁定功能测试
log.info("\n=== Test 3: Lock Functionality Test ===")
local testStack = ContainerStack()
testStack:scan("left")

-- 锁定单个槽位
log.info("Locking slot 1")
local lockId1 = testStack:lock(1)
log.info("Lock ID:", lockId1)

-- 同时锁定多个槽位
log.info("Locking slots 2,3,4")
local lockId2 = testStack:lock({ 2, 3, 4 })
log.info("Lock ID:", lockId2)

-- 解锁测试
log.info("Unlocking lock ID:", lockId1)
testStack:unLock(lockId1)
log.info("Unlock success")

-- 消耗锁定物品
local output2 = testStack:consumeLock(lockId2)
if not output2 then
    log.error("consumeLock error")
    error()
end
output2("right")
pressEnter()

-- Test 4: 按数量锁定
log.info("\n=== Test 4: Lock by Count ===")
local countStack = ContainerStack()
countStack:scan("left")

-- 假设槽位5、6有足够的物品
local lockRequest = {
    { slotOrName = 5, countOrAmount = 32 }, -- 锁定 32 物品
    { slotOrName = 6, countOrAmount = 16 }  -- 锁定 16 物品
}

log.info("Lock by count request:")
for i, req in ipairs(lockRequest) do
    log.info(string.format("  Slot %d: %d items", req.slotOrName, req.countOrAmount))
end

local countLockId = countStack:lockByCount(lockRequest)
log.info("Lock ID:", countLockId)

-- 验证未锁定物品数量
local remaining = countStack:getContext()
for slot, item in pairs(remaining) do
    if type(slot) == "string" then
        goto continue
    end
    if item then
        log.info(string.format("  Slot %d remaining: %s x%d", slot, item.name, item.count))
    end
    ::continue::
end
pressEnter()

-- Test 5: File save and restore
log.info("\n=== Test 5: File Save and Restore ===")
local saveStack = ContainerStack()
saveStack:scan("left")

local saveFile = "container_save.dat"
log.info("Saving to file:", saveFile)
saveStack:saveAsFile(saveFile)

local restoreStack = ContainerStack()
log.info("Restoring from file")
restoreStack:reloadFromFile(saveFile)
fs.delete(saveFile)

log.info("Restored container name:", restoreStack.peripheralName)
log.info("Restored container size:", restoreStack.size)
log.info("Restored update time:", restoreStack.updateTime)

-- Clean up test file

log.info("Test file cleanup complete")
pressEnter()

-- Test 6: Error handling test
log.info("\n=== Test 6: Error Handling Test ===")

-- Test locking non-existent slot
local errorStack = ContainerStack()
errorStack:scan("left")

log.warn("Attempting to lock non-existent slot 999...")
local status, errMsg = pcall(function()
    errorStack:lock(999)
end)
if not status then
    log.error("Expected error:", errMsg)
end

-- Test unlocking non-existent ID
log.warn("Attempting to unlock non-existent lock ID...")
local status, errMsg = pcall(function()
    errorStack:unLock("999999")
end)
if not status then
    log.error("Expected error:", errMsg)
end

log.info("\n=== All tests completed ===")
print("Check log.txt for detailed log information")
