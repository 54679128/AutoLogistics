-- transferTicketTest.lua
require("_steup")

local ContainerStack = require("ContainerStack")
local TransferTicket = require("TransferTicket")

local function waitForPlayer(msg)
  print("\n>>> ACTION REQUIRED <<<")
  print(msg)
  print("Press Enter when done...")
  read()
end

local function autoPause()
  print("\nPress Enter to continue to next test...")
  read()
end

print("=== TransferTicket Integration Test ===")
print("This test verifies ticket creation, execution, and failure cases.")
print("Make sure your computer is connected as follows:")
print("  - 'left'  : Source container (with items & fluid)")
print("  - 'right' : Target container (empty, accepts items/fluid)\n")

autoPause()

-- ===== 步骤1：准备源容器 =====
print("🔍 Scanning source container ('left')...")
local source = ContainerStack()
local ok, err = source:scan("left")
if not ok then
  print("❌ Failed to scan 'left': " .. tostring(err))
  return
end

local ctx = source:getContext()

-- 锁定资源：至少一个物品 + 一种流体
local requests = {}

-- 物品：找第一个有 ≥5 个的槽
for slot = 1, 16 do
  local res = ctx[slot]
  if res and res.quantity >= 5 then
    table.insert(requests, { slotOrName = slot, countOrAmount = 5 })
    print(("✅ Found %d x %s in slot %d. Will lock 5 for test."):format(
      res.quantity, res.name, slot))
    break
  end
end

-- 流体：找第一个非空流体
for name, res in pairs(ctx) do
  if type(name) == "string" and res.quantity >= 100 then
    table.insert(requests, { slotOrName = name, countOrAmount = 100 })
    print(("✅ Found %d mB of %s. Will lock 100 mB for test."):format(res.quantity, name))
    break
  end
end

if #requests == 0 then
  print("❌ No suitable items or fluids found in 'left' container.")
  print("Please ensure:")
  print("  - At least one slot has ≥5 stackable items")
  print("  - At least one fluid tank has ≥100 mB")
  return
end

-- 创建票据
print("\n🎟️ Creating transfer ticket...")
local receipt = source:lockByCount(requests)
if not receipt then
  print("❌ Failed to create lock receipt")
  return
end

local ticket = TransferTicket(source, receipt)
print("✅ Ticket created successfully.\n")

-- ===== Test 1: 正常执行 =====
print("--- Test 1: Normal execution ---")
print("Target: 'right' container")
local success = ticket:execute("right")
print(success and "✅ SUCCESS" or "❌ FAILED")
autoPause()

-- ===== Test 2: 重复执行（应失败）=====
print("--- Test 2: Execute same ticket again (should fail) ---")
local success2 = ticket:execute("right")
if not success2 then
  print("✅ Correctly rejected duplicate execution.")
else
  print("⚠️ WARNING: Ticket allowed double spend! This is a bug.")
end
autoPause()

-- ===== Test 3: 源外设断开 =====
print("--- Test 3: Source peripheral disconnected ---")
waitForPlayer([[
Please DISCONNECT the 'left' peripheral now.
You can do this by:
  - Breaking the cable between computer and source container, OR
  - Removing the source container itself.

Do NOT reconnect it until the next test!]])

local success3 = ticket:execute("right")
if not success3 then
  print("✅ Correctly failed due to missing source.")
else
  print("⚠️ WARNING: Execution succeeded despite missing source! Bug!")
end

-- 重新连接源外设
waitForPlayer([[
Now please RECONNECT the 'left' peripheral.
Ensure the computer can see it again before continuing.]])
autoPause()

-- ===== Test 4: 资源被外部移除 =====
print("--- Test 4: Resource removed externally after locking ---")
print("Creating a new small ticket (1 item from a slot)...")

local tempSource = ContainerStack()
ok, err = tempSource:scan("left")
if not ok then
  print("❌ Can't rescan source. Skipping test 4.")
else
  local tempCtx = tempSource:getContext()
  local testSlot = nil
  for i = 1, 16 do
    if tempCtx[i] and tempCtx[i].quantity >= 1 then
      testSlot = i
      break
    end
  end

  if testSlot then
    local tempReceipt = tempSource:lock({ testSlot })
    if tempReceipt then
      local tempTicket = TransferTicket(tempSource, tempReceipt)
      waitForPlayer(string.format([[
Please MANUALLY REMOVE ALL ITEMS from slot %d of the 'left' container.
(Open the container and take out the contents of slot %d.)]], testSlot, testSlot))

      local success4 = tempTicket:execute("right")
      if not success4 then
        print("✅ Correctly failed: resource no longer available.")
      else
        print("⚠️ WARNING: Transferred non-existent resource! Bug!")
      end
    else
      print("❌ Failed to lock slot for test 4.")
    end
  else
    print("No non-empty slot found for test 4.")
  end
end

print("\n=== All tests completed! ===")
print("Thank you for your participation.")
