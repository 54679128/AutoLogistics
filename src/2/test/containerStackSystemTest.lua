require("_steup")
local log             = require("lib.log")
local ContainerScan   = require("ContainerStack.ContainerScan")
local ResourceManager = require("ContainerStack.ResourceManager")
local ContainerStackM = require("ContainerStack.ContainerStackM")
local preFilter       = require("preDefinedFilter")
local util            = require("lib.util")
local Filter          = require("Filter")

local function pressEnter()
    print("\nPress enter to continue...")
    read()
end

-- 辅助函数：打印资源表 → 改为日志
local function printResources(resources, label)
    log.info(string.format("\n%s (total: %d):", label, #resources or 0))
    for key, resource in pairs(resources or {}) do
        if type(key) == "number" then
            log.info(string.format("  Slot %d: %s x%d", key, resource.name, resource.quantity))
        elseif type(key) == "string" then
            log.info(string.format("  %s: %s x%d", key, resource.name, resource.quantity))
        end
    end
end

log.info("=== Container System Test Suite ===")
log.info("Testing: ContainerScan, ResourceManager, ContainerStackM")

-- 测试一：ContainerScan 基础功能测试
log.info("\n=== Test 1: ContainerScan Module ===")
log.info("Testing isContainer function...")

-- 测试存在的容器
local containerName = "left"
local isContainer = ContainerScan.isContainer(containerName)
log.info(string.format("Container '%s' is container: %s", containerName, tostring(isContainer)))

-- 测试不存在的容器
local fakeContainer = "right"
isContainer = ContainerScan.isContainer(fakeContainer)
log.info(string.format("Container '%s' is container: %s", fakeContainer, tostring(isContainer)))

-- 测试扫描功能
log.info("\nTesting scan function...")
local resources = ContainerScan.scan(containerName)
if resources then
    log.info(string.format("Successfully scanned container '%s'", containerName))
    local itemCount = 0
    local fluidCount = 0
    for key, _ in pairs(resources) do
        if type(key) == "number" then
            itemCount = itemCount + 1
        else
            fluidCount = fluidCount + 1
        end
    end
    log.info(string.format("  Found %d items and %d fluids", itemCount, fluidCount))

    -- 打印前几个物品作为示例
    local sampleCount = 0
    for slot, resource in pairs(resources) do
        if type(slot) == "number" and sampleCount < 3 then
            log.info(string.format("    Slot %d: %s x%d", slot, resource.name, resource.quantity))
            sampleCount = sampleCount + 1
        end
    end
else
    log.info(string.format("Failed to scan container '%s'", containerName))
end

pressEnter()

-- 测试二：ResourceManager 基础功能测试
log.info("\n=== Test 2: ResourceManager Module ===")
local rm = ResourceManager()

-- 初始化资源
log.info("1. Initializing resources...")
local testResources = {
    [1] = { name = "minecraft:iron_ingot", quantity = 64, resourceType = "item" },
    [2] = { name = "minecraft:gold_ingot", quantity = 32, resourceType = "item" },
    [3] = { name = "minecraft:diamond", quantity = 16, resourceType = "item" },
    ["water"] = { name = "minecraft:water", quantity = 1000, resourceType = "fluid" },
    ["lava"] = { name = "minecraft:lava", quantity = 500, resourceType = "fluid" }
}

rm:update(testResources)
log.info("Resources initialized successfully")

-- 搜索功能测试
log.info("\n2. Testing search function...")

-- 定义过滤器
local ironFilter = preFilter.withName("minecraft:iron_ingot")

local ironResult = rm:search(ironFilter)
if util.len(ironResult) < 1 then
    log.error("The material that should exist was not detected")
end
log.info(string.format("Search for iron ingots: found %d results", util.len(ironResult)))
for slot, info in pairs(ironResult) do
    log.info(string.format("  Slot %s: %s x%d", slot, info.name, info.quantity))
end

-- 流体过滤器
local fluidFilter = preFilter.withType("fluid")

local fluidResult = rm:search(fluidFilter)
if util.len(fluidResult) < 1 then
    log.error("The material that should exist was not detected")
end
log.info(string.format("\nSearch for fluids: found %d results", util.len(fluidResult)))
for name, info in pairs(fluidResult) do
    log.info(string.format("  %s: %s x%d", name, info.name, info.quantity))
end

pressEnter()

-- 预定功能测试
log.info("\n3. Testing order/reservation system...")

-- 创建预定请求
local orderRequest = {
    [1] = { name = "minecraft:iron_ingot", quantity = 32 },
    [2] = { name = "minecraft:gold_ingot", quantity = 16 },
}

log.info("Attempting to reserve resources...")
local receipt = rm:Order(orderRequest)

if receipt then
    log.info(string.format("Reservation successful! Receipt: %s", receipt))

    -- 检查票据状态
    local isAvailable = rm:isAvailable(receipt)
    log.info(string.format("Receipt available: %s", tostring(isAvailable)))

    -- 获取预留资源
    local reserved = rm:getReserve(receipt)
    if not reserved then
        log.error("reserved is NIL!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        error("reserved is NIL!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    end
    log.info(string.format("Reserved resources count: %d", util.len(reserved)))
    for slot, info in pairs(reserved) do
        log.info(string.format("  Reserved - Slot %s: %s x%d", slot, info.name, info.quantity))
    end

    -- 搜索可用资源（应该减少）
    local availableIron = rm:search(ironFilter)
    for slot, info in pairs(availableIron) do
        log.info(string.format("  Available after reservation - Slot %s: %s x%d", slot, info.name, info.quantity))
    end
else
    log.error("Reservation failed!")
end

pressEnter()

-- 释放功能测试
log.info("\n4. Testing release function...")
if receipt then
    log.info(string.format("Releasing receipt: %s", receipt))
    rm:release(receipt)

    -- 检查票据是否已释放
    local stillAvailable = rm:isAvailable(receipt)
    log.info(string.format("Receipt still available after release: %s", tostring(stillAvailable)))

    -- 验证资源已恢复
    local restoredIron = rm:search(ironFilter)
    for slot, info in pairs(restoredIron) do
        log.info(string.format("  Restored - Slot %s: %s x%d", slot, info.name, info.quantity))
        if info.quantity == 64 then
            log.info("   Resource quantity correctly restored")
        end
    end
end

-- 票据过期测试
log.info("\n5. Testing receipt expiration...")
local testOrder = {
    [3] = { name = "minecraft:diamond", quantity = 4 }
}

local tempReceipt = rm:Order(testOrder)
if tempReceipt then
    log.info(string.format("Created test receipt: %s", tempReceipt))

    -- 模拟票据过期（手动设置创建时间为10秒前）
    rm.createdAt[tempReceipt] = rm.createdAt[tempReceipt] - 11000

    local beforeCleanup = rm:isAvailable(tempReceipt)
    log.info(string.format("Before cleanup - receipt available: %s", tostring(beforeCleanup)))

    -- 运行清理
    rm:cleanupExpiration()

    local afterCleanup = rm:isAvailable(tempReceipt)
    log.info(string.format("After cleanup - receipt available: %s", tostring(afterCleanup)))

    if not afterCleanup then
        log.info(" Expired receipt successfully cleaned up")
    end
end

pressEnter()

-- 错误处理测试
log.info("\n6. Testing error handling...")

-- 测试预定不存在的资源
log.info("Attempting to order non-existent resource...")
local invalidOrder = {
    [999] = { name = "minecraft:emerald", quantity = 10 }
}

local invalidReceipt = rm:Order(invalidOrder)
log.info(string.format("Order result for non-existent resource: %s",
    invalidReceipt and "success (unexpected!)" or "failed (expected)"))

-- 测试预定数量不足
log.info("\nAttempting to order more than available...")
local excessiveOrder = {
    [1] = { name = "minecraft:iron_ingot", quantity = 100 }
}

local excessiveReceipt = rm:Order(excessiveOrder)
log.info(string.format("Order result for excessive quantity: %s",
    excessiveReceipt and "success (unexpected!)" or "failed (expected)"))

-- 测试访问无效票据
log.info("\nAttempting to access invalid receipt...")
local fakeReceipt = "INVALID_123"
local reserved = rm:getReserve(fakeReceipt)
log.info(string.format("Access result for invalid receipt: %s",
    reserved and "success (unexpected!)" or "failed (expected)"))

pressEnter()

-- 测试三：ContainerStackM 集成测试
log.info("\n=== Test 3: ContainerStackM Integration ===")
log.info("Creating ContainerStackM instance...")

local containerM = ContainerStackM(containerName)

-- 刷新测试
log.info("\n1. Testing refresh function...")
local refreshSuccess = containerM:refresh()
log.info(string.format("Refresh successful: %s", tostring(refreshSuccess)))

if refreshSuccess then
    -- 搜索测试
    log.info("\n2. Testing search through ContainerStackM...")
    local searchFilter = preFilter.withType("item")

    local searchResult = containerM:search(searchFilter)
    log.info(string.format("Found %d matching items", util.len(searchResult) or 0))

    -- 预订测试
    log.info("\n3. Testing reservation through ContainerStackM...")
    if next(searchResult) ~= nil then
        local firstKey, firstResource = next(searchResult)
        local reserveRequest = {
            ---@cast firstResource -nil
            [firstKey] = {
                name = firstResource.name,
                quantity = math.min(firstResource.quantity, 1)
            }
        }
        ---@cast firstResource -nil
        log.info(string.format("Reserving %s x%d from slot %s",
            firstResource.name, reserveRequest[firstKey].quantity, firstKey))

        local stackReceipt = containerM:reserve(reserveRequest)

        if stackReceipt then
            log.info(string.format("Reservation successful! Receipt: %s", stackReceipt))

            local stackReserved = containerM:getReserve(stackReceipt)
            log.info(string.format("Reserved through ContainerStackM: %d items",
                #stackReserved or 0))

            local available = containerM:isAvailable(stackReceipt)
            log.info(string.format("Receipt available: %s", tostring(available)))

            -- 释放测试
            log.info("\nTesting release through ContainerStackM...")
            containerM:release(stackReceipt)

            local afterRelease = containerM:isAvailable(stackReceipt)
            log.info(string.format("Receipt available after release: %s", tostring(afterRelease)))
        end
    end

    -- 清理过期票据测试
    log.info("\n4. Testing cleanup expiration...")
    containerM:cleanupExpiration()
    log.info("Cleanup completed")

    -- 无效票据测试
    log.info("\n5. Testing invalidate function...")
    local fakeReceiptM = "FAKE_RECEIPT_123"
    log.info("Attempting to invalidate non-existent receipt...")
    containerM:invalidate(fakeReceiptM)
    log.info("Invalidate completed without crash")
end

pressEnter()

-- 综合测试：完整的业务流程
log.info("\n=== Test 4: Complete Workflow ===")
log.info("Simulating complete resource management workflow...")

local workflowRM = ResourceManager()

-- 1. 初始资源
workflowRM:update({
    [1] = { name = "minecraft:cobblestone", quantity = 64, resourceType = "item" },
    [2] = { name = "minecraft:cobblestone", quantity = 64, resourceType = "item" },
    [3] = { name = "minecraft:stick", quantity = 32, resourceType = "item" }
})

log.info("1. Initial resources set up")

-- 2. 搜索需要合成的资源
local cobbleFilter = preFilter.withName("minecraft:cobblestone")

local availableCobble = workflowRM:search(cobbleFilter)
log.info(string.format("2. Found %d slots with cobblestone", util.len(availableCobble) or 0))

-- 3. 预定资源进行合成
local totalNeeded = 128
local cobbleOrder = {}
local remainingNeed = totalNeeded

for slot, info in pairs(availableCobble) do
    if remainingNeed <= 0 then break end

    local takeAmount = math.min(info.quantity, remainingNeed)
    cobbleOrder[slot] = { name = info.name, quantity = takeAmount }
    remainingNeed = remainingNeed - takeAmount
end

if remainingNeed == 0 then
    log.info("3. Sufficient cobblestone found for order")

    local workflowReceipt = workflowRM:Order(cobbleOrder)
    if workflowReceipt then
        log.info(string.format("4. Resources reserved. Receipt: %s", workflowReceipt))

        log.info("5. Simulating crafting process...")
        sleep(1)

        workflowRM:consume(workflowReceipt)
        log.info("6. Crafting completed, receipt invalidated")

        local afterCraftCobble = workflowRM:search(cobbleFilter)
        local totalRemaining = 0
        for _, info in pairs(afterCraftCobble) do
            totalRemaining = totalRemaining + info.quantity
        end

        local expectedRemaining = 64 + 64 - 128
        log.info(string.format("7. Cobblestone remaining: %d (expected: %d)",
            totalRemaining, expectedRemaining))

        if totalRemaining == expectedRemaining then
            log.info("✓ Workflow test PASSED")
        else
            log.info("✗ Workflow test FAILED - resource count mismatch")
        end
    else
        log.info("✗ Workflow test FAILED - reservation failed")
    end
else
    log.info(string.format("✗ Workflow test FAILED - insufficient cobblestone (need %d more)",
        remainingNeed))
end

log.info("\n=== All Tests Completed ===")
log.info("Summary:")
log.info("1. ContainerScan: Basic scanning functionality")
log.info("2. ResourceManager: Full reservation system with error handling")
log.info("3. ContainerStackM: Integrated container management")
log.info("4. Workflow: Complete resource management scenario")
log.info("\nCheck log.txt for detailed execution logs")
