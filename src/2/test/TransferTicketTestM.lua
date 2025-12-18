-- TransferTicketTest.lua
require("_steup")
local log = require("lib.log")
local Object = require("lib.Object")
local ContainerStackM = require("ContainerStack.ContainerStackM")
local TransferTicketM = require("ContainerStack.TransferTicketM")
local preFilter = require("preDefinedFilter")
local util = require("lib.util")

local function pressEnter()
    print("\nPress enter to continue...")
    read()
end

-- 辅助函数：打印票据信息
local function printReceiptInfo(receipt, label)
    log.info(string.format("\n%s:", label))
    if type(receipt) == "string" then
        log.info(string.format("  Receipt: %s", receipt))
    else
        log.info(string.format("  Receipt ID: %s", receipt.receipt or "N/A"))
        log.info(string.format("  Container: %s", receipt.containerStack.peripheralName or "N/A"))
    end
end

-- 辅助函数：打印转移结果
local function printTransferResult(success, details)
    log.info(string.format("  Success: %s", tostring(success)))
    if details then
        log.info(string.format("  Details: %s", textutils.serialise(details)))
    end
end

log.info("=== TransferTicket System Test Suite ===")
log.info("Testing: TransferTicketM module functionality")

-- 测试一：基础功能测试
log.info("\n=== Test 1: Basic TransferTicketM Functionality ===")

-- 创建测试容器管理器
log.info("1. Creating ContainerStackM instance...")
local testContainerName = "left" -- 修改为实际存在的容器
local containerM = ContainerStackM(testContainerName)

-- 刷新容器内容
log.info(string.format("Refreshing container '%s'...", testContainerName))
local refreshSuccess = containerM:refresh()
if not refreshSuccess then
    log.error("Failed to refresh container. Please ensure the container exists and is accessible.")
    return
end
log.info("Container refreshed successfully")

-- 搜索可用的资源
log.info("\n2. Searching for available resources...")
local itemFilter = preFilter.withType("item")
local searchResult = containerM:search(itemFilter)

if util.len(searchResult) == 0 then
    log.warn("No items found in container. Adding test items...")
    -- 这里可以添加一些测试物品，或者提示用户添加
    log.info("Please add some items to the container and press enter to continue...")
    read()
    containerM:refresh()
    searchResult = containerM:search(itemFilter)

    if util.len(searchResult) == 0 then
        log.error("Still no items found. Test cannot proceed.")
        return
    end
end

log.info(string.format("Found %d item slots", util.len(searchResult)))

-- 选择第一个可用资源进行测试
local firstKey, firstResource = next(searchResult)
if not firstResource then
    log.error("No Item")
    return
end
log.info(string.format("Selected test item: Slot %s - %s x%d",
    firstKey, firstResource.name, firstResource.quantity))

pressEnter()

-- 测试二：票据创建和可用性检查
log.info("\n=== Test 2: Ticket Creation and Availability ===")

-- 创建预定请求
local reserveAmount = math.min(firstResource.quantity, 4)
local reserveRequest = {
    [firstKey] = { name = firstResource.name, quantity = reserveAmount }
}

log.info(string.format("Reserving %s x%d from slot %s...",
    firstResource.name, reserveAmount, firstKey))

local receipt = containerM:reserve(reserveRequest)
if not receipt then
    log.error("Failed to reserve resources. Test cannot proceed.")
    return
end

printReceiptInfo(receipt, "Reservation created")

-- 检查票据在容器中的可用性
local availableInContainer = containerM:isAvailable(receipt)
log.info(string.format("Receipt available in container: %s", tostring(availableInContainer)))

-- 创建转移票据
log.info("\nCreating TransferTicketM instance...")
local transferTicket = TransferTicketM(containerM, receipt)

-- 检查票据可用性
log.info("Checking ticket availability...")
local isAvailable = transferTicket:isAvailable()
log.info(string.format("Transfer ticket available: %s", tostring(isAvailable)))

if not isAvailable then
    log.error("Transfer ticket not available. Test cannot proceed.")
    return
end

pressEnter()

-- 测试三：转移功能测试
log.info("\n=== Test 3: Transfer Functionality ===")

-- 确定目标容器
local targetContainer = "right" -- 修改为实际存在的目标容器
log.info(string.format("Target container: %s", targetContainer))

-- 检查目标容器是否存在
local targetPeripheral = peripheral.wrap(targetContainer)
if not targetPeripheral then
    log.warn(string.format("Target container '%s' not found. Using 'left' as fallback.", targetContainer))
    targetContainer = testContainerName -- 回退到同一个容器
end

log.info("Attempting resource transfer...")

-- 执行转移
local transferSuccess = transferTicket:use(targetContainer)

printTransferResult(transferSuccess)

if transferSuccess then
    log.info("Transfer completed successfully!")

    -- 验证转移后票据状态
    log.info("\nChecking ticket status after transfer...")
    local afterUseAvailable = transferTicket:isAvailable()
    log.info(string.format("Ticket available after use: %s", tostring(afterUseAvailable)))

    if not afterUseAvailable then
        log.info("✓ Ticket correctly marked as used")
    else
        log.warn("✗ Ticket should not be available after use")
    end
else
    log.error("Transfer failed!")

    -- 检查失败原因
    log.info("Checking if receipt is still valid...")
    local receiptStillValid = containerM:isAvailable(receipt)
    log.info(string.format("Original receipt still valid: %s", tostring(receiptStillValid)))

    if receiptStillValid then
        log.info("Resources should still be reserved. Cleaning up...")
        containerM:release(receipt)
        log.info("Resources released back to container")
    end
end

pressEnter()

-- 测试四：错误处理测试
log.info("\n=== Test 4: Error Handling Tests ===")

-- 4.1 测试已使用的票据
log.info("1. Testing used ticket...")
local usedResult = transferTicket:use(targetContainer)
log.info(string.format("Attempting to use already-used ticket: %s",
    usedResult and "SUCCESS (unexpected)" or "FAILED (expected)"))

-- 4.2 测试过期票据
log.info("\n2. Testing expired ticket...")

-- 创建新的票据
local newReserve = containerM:reserve(reserveRequest)
if newReserve then
    local newTicket = TransferTicketM(containerM, newReserve)

    -- 模拟过期（修改创建时间）
    log.info("Simulating ticket expiration...")
    newTicket.createdAt = os.epoch("local") - 10 * 1000 -- 设置为10秒前

    local expiredAvailable = newTicket:isAvailable()
    log.info(string.format("Expired ticket available: %s", tostring(expiredAvailable)))

    local expiredTransfer = newTicket:use(targetContainer)
    log.info(string.format("Attempting to use expired ticket: %s",
        expiredTransfer and "SUCCESS (unexpected)" or "FAILED (expected)"))

    -- 清理
    containerM:release(newReserve)
end

-- 4.3 测试无效票据
log.info("\n3. Testing invalid receipt...")
local invalidTicket = TransferTicketM(containerM, "INVALID_RECEIPT_123")
local invalidAvailable = invalidTicket:isAvailable()
log.info(string.format("Invalid ticket available: %s", tostring(invalidAvailable)))

-- 4.4 测试容器不存在的情况
log.info("\n4. Testing non-existent target container...")
local newReserve2 = containerM:reserve(reserveRequest)
if newReserve2 then
    local testTicket = TransferTicketM(containerM, newReserve2)

    local nonExistentTarget = "non_existent_container_xyz"
    local nonExistentResult = testTicket:use(nonExistentTarget)
    log.info(string.format("Attempting to transfer to non-existent container: %s",
        nonExistentResult and "SUCCESS (unexpected)" or "FAILED (expected)"))

    -- 清理
    containerM:release(newReserve2)
end

pressEnter()

-- 测试五：批量转移测试
log.info("\n=== Test 5: Batch Transfer Test ===")

-- 搜索多个资源
log.info("Searching for multiple resources to reserve...")
local allItems = containerM:search(itemFilter)
local batchRequest = {}
local batchCount = 0

-- 选择前3个不同的资源（如果可用）
for slot, info in pairs(allItems) do
    if batchCount >= 3 then break end

    -- 确保不是重复的物品类型
    local isDuplicate = false
    for _, reqInfo in pairs(batchRequest) do
        if reqInfo.name == info.name then
            isDuplicate = true
            break
        end
    end

    if not isDuplicate and info.quantity >= 1 then
        batchRequest[slot] = { name = info.name, quantity = 1 }
        batchCount = batchCount + 1
        log.info(string.format("  Added to batch: Slot %s - %s x1", slot, info.name))
    end
end

if batchCount > 0 then
    log.info(string.format("\nReserving %d different items...", batchCount))
    local batchReceipt = containerM:reserve(batchRequest)

    if batchReceipt then
        printReceiptInfo(batchReceipt, "Batch reservation created")

        local batchTicket = TransferTicketM(containerM, batchReceipt)

        log.info("Attempting batch transfer...")
        local batchSuccess = batchTicket:use(targetContainer)

        printTransferResult(batchSuccess, "Batch transfer")

        if batchSuccess then
            log.info("✓ Batch transfer completed successfully!")
        else
            log.error("✗ Batch transfer failed")
            -- 清理
            containerM:release(batchReceipt)
        end
    else
        log.error("Failed to reserve batch resources")
    end
else
    log.warn("Not enough different items for batch test")
end

pressEnter()

-- 测试六：流体转移测试（如果可用）
log.info("\n=== Test 6: Fluid Transfer Test ===")

-- 搜索流体
local fluidFilter = preFilter.withType("fluid")
local fluidResult = containerM:search(fluidFilter)

if util.len(fluidResult) > 0 then
    log.info("Fluid resources found:")
    for fluidName, info in pairs(fluidResult) do
        log.info(string.format("  %s: %s x%d", fluidName, info.name, info.quantity))
    end

    -- 选择第一个流体
    local firstFluidName, firstFluidInfo = next(fluidResult)
    if not firstFluidInfo then
        log.error("No fluid")
        return
    end
    local fluidReserveRequest = {
        [firstFluidName] = { name = firstFluidInfo.name, quantity = 100 } -- 100mb
    }

    log.info(string.format("\nReserving fluid: %s x100", firstFluidInfo.name))
    local fluidReceipt = containerM:reserve(fluidReserveRequest)

    if fluidReceipt then
        local fluidTicket = TransferTicketM(containerM, fluidReceipt)

        log.info("Attempting fluid transfer...")
        local fluidSuccess = fluidTicket:use(targetContainer)

        printTransferResult(fluidSuccess, "Fluid transfer")

        if fluidSuccess then
            log.info("✓ Fluid transfer completed successfully!")
        else
            log.error("✗ Fluid transfer failed")
            containerM:release(fluidReceipt)
        end
    else
        log.error("Failed to reserve fluid")
    end
else
    log.info("No fluid resources found in container (this is normal if container has no fluids)")
end

pressEnter()

-- 测试七：综合工作流程测试
log.info("\n=== Test 7: Comprehensive Workflow Test ===")

log.info("Simulating a complete resource management workflow:")
log.info("1. Search resources → 2. Reserve → 3. Create ticket → 4. Transfer → 5. Verify")

-- 搜索可用资源
local workflowFilter = preFilter.withType("item")
local workflowSearch = containerM:search(workflowFilter)

if util.len(workflowSearch) > 0 then
    log.info("Step 1: Found resources for workflow")

    -- 选择资源进行预定
    local workflowReserve = {}
    local reservedCount = 0

    for slot, info in pairs(workflowSearch) do
        if reservedCount < 2 and info.quantity >= 2 then
            workflowReserve[slot] = { name = info.name, quantity = 2 }
            reservedCount = reservedCount + 1
            log.info(string.format("  Will reserve: Slot %s - %s x2", slot, info.name))
        end
    end

    if reservedCount > 0 then
        log.info("\nStep 2: Reserving resources...")
        local workflowReceipt = containerM:reserve(workflowReserve)

        if workflowReceipt then
            printReceiptInfo(workflowReceipt, "Workflow reservation")

            log.info("\nStep 3: Creating transfer ticket...")
            local workflowTicket = TransferTicketM(containerM, workflowReceipt)

            -- 检查票据
            local workflowAvailable = workflowTicket:isAvailable()
            log.info(string.format("Workflow ticket available: %s", tostring(workflowAvailable)))

            if workflowAvailable then
                log.info("\nStep 4: Executing transfer...")
                local workflowSuccess = workflowTicket:use(targetContainer)

                if workflowSuccess then
                    log.info("✓ Step 4: Transfer successful")

                    log.info("\nStep 5: Verification...")
                    -- 检查票据状态
                    local finalStatus = workflowTicket:isAvailable()
                    log.info(string.format("Ticket status after workflow: %s",
                        finalStatus and "AVAILABLE (unexpected)" or "USED (expected)"))

                    -- 检查容器中是否还有该票据
                    local receiptInContainer = containerM:isAvailable(workflowReceipt)
                    log.info(string.format("Receipt in container after workflow: %s",
                        tostring(receiptInContainer)))

                    if not finalStatus and not receiptInContainer then
                        log.info("✓ Workflow test PASSED - All steps completed successfully")
                    else
                        log.warn("✗ Workflow test - Unexpected state")
                    end
                else
                    log.error("✗ Step 4: Transfer failed")
                    containerM:release(workflowReceipt)
                end
            else
                log.error("✗ Step 3: Ticket not available")
                containerM:release(workflowReceipt)
            end
        else
            log.error("✗ Step 2: Reservation failed")
        end
    else
        log.warn("Not enough resources for workflow test")
    end
else
    log.info("No suitable resources found for workflow test")
end

log.info("\n=== All TransferTicket Tests Completed ===")
log.info("Summary:")
log.info("1. Basic functionality: Ticket creation and availability checks")
log.info("2. Transfer execution: Single and batch transfers")
log.info("3. Error handling: Used, expired, and invalid tickets")
log.info("4. Fluid transfer: If applicable")
log.info("5. Workflow test: Complete resource management scenario")

log.info("\nCheck log.txt for detailed execution logs")
log.info("End of TransferTicket test suite")
