local inventorys = table.pack(peripheral.find("inventory"))
local chests = { input = {}, left = {}, right = {}, buffer = {} }

local function getLength(aTable)
    local i = 0
    for _, _ in pairs(aTable) do
        i = i + 1
    end
    return i
end

local function getIndex(chest)
    local strNumber, _ = string.gsub(chest.getItemDetail(1).displayName, "%D", "")
    return tonumber(strNumber)
end

local function addToChests(index, chestType, chest)
    if chestType == "input" then
        table.insert(chests.input, index, chest)
    elseif chestType == "left" then
        table.insert(chests.left, index, chest)
    elseif chestType == "right" then
        table.insert(chests.right, index, chest)
    elseif chestType == "buffer" then
        table.insert(chests.buffer, index, chest)
    end
end

local function getChestType(chest)
    local item = chest.getItemDetail(1)
    --if not item then return nil end

    local name = item.displayName:lower()
    if name:find("in") then return "input" end
    if name:find("left") then return "left" end
    if name:find("right") then return "right" end
    if name:find("buffer") then return "buffer" end
    return nil
end

local function isEmpty(chest)
    local list = chest.list()
    for slot, item in ipairs(list) do
        if slot ~= 1 and item then
            return false
        end
    end
    return true
end

local function getMaterials(chest)
    local list = chest.list()
    local firstMaterName
    local firstMaterSlot
    local secondMaterName
    local secondMaterSlot

    for slot, item in pairs(list) do
        if slot == 1 then
            goto continue
        end
        if firstMaterName == nil then
            firstMaterName = item.name
            firstMaterSlot = slot
        elseif firstMaterName and secondMaterName == nil and item.name ~= firstMaterName then
            secondMaterName = item.name
            secondMaterSlot = slot
            break
        end
        ::continue::
    end
    return firstMaterName, secondMaterName
end

---从缓存向一系列目标容器均匀转移物品
---@param name string
---@param buffer ccTweaked.peripherals.Inventory
---@param target table{ccTweaked.peripherals.Inventory,...}
local function uniformToTarget(name, buffer, target)
    --统计该物品总数，顺便查找哪些槽位有需要的物品
    local itemSlots = {}
    local itemTotalCount = 0
    local itemList = buffer.list()
    for slot, item in pairs(itemList) do
        if slot == 1 then
            goto continue
        end
        if item.name ~= name then
            goto continue
        end
        itemTotalCount = itemTotalCount + item.count
        table.insert(itemSlots, slot)
        ::continue::
    end
    --计算每个箱子应得到的物品数量
    local portion = itemTotalCount / getLength(target)
    for _, leftChest in pairs(target) do
        local willTransfer = portion
        local notTransfer = 0
        for _, slot in ipairs(itemSlots) do
            notTransfer = notTransfer + leftChest.pullItems(peripheral.getName(buffer), slot, willTransfer - notTransfer)
            if notTransfer == willTransfer then
                break
            end
        end
    end
end

local function waitForReady(input)
    while true do
        local lastCount = 0
        local newCount = 0
        for _, item in pairs(input.list()) do
            if item then
                lastCount = lastCount + item.count
            end
        end
        sleep(2)
        for _, item in pairs(input.list()) do
            if item then
                newCount = newCount + item.count
            end
        end
        if newCount == lastCount then
            break
        end
        print("isn't ready")
    end
    print("ready")
end

local function transferToBuffer(source, target)
    local sourceItemList = source.list()
    for slot, item in pairs(sourceItemList) do
        if slot == 1 then
            goto continue
        end
        while true do
            local count = item.count
            local transferCount = source.pushItems(peripheral.getName(target), slot)
            if count == transferCount then
                break
            end
        end
        ::continue::
    end
end

local function classifyByFeatures()
    local aChests = {}
    -- 用名字分类
    for k, inventory in pairs(inventorys) do
        if k == "n" then
            goto continue
        end
        local peripheralType = peripheral.getName(inventory)
        local name = string.match(peripheralType, "^(.+)_%d+$")
        if not aChests[name] then
            aChests[name] = {}
        end
        table.insert(aChests[name], peripheral.getName(inventory))
        ::continue::
    end
    -- 用物品分类
    for k, inventory in pairs(inventorys) do
        if k == "n" then
            goto continue
        end
        local itemList = inventory.list()
        local blackList = {}
        for _, item in pairs(itemList) do
            local name = item.name
            if not aChests[name] then
                aChests[name] = {}
            end
            if not blackList[name] then
                table.insert(aChests[name], peripheral.getName(inventory))
                blackList[name] = true
            end
        end
        ::continue::
    end
    return aChests
end

---按特征展示分类结果
---@param featureTable table 使用classifyByFeatures函数得到
---@see classifyByFeatures
local function displayClassificationByFeatures(featureTable)
    parallel.waitForAny(function()
        for characterized, talee in pairs(featureTable) do
            textutils.slowPrint("These containers:")
            for _, inventory in pairs(talee) do
                textutils.slowPrint(inventory)
            end
            textutils.slowPrint("Characterized by: " .. characterized)
        end
    end, function()
        os.pullEvent("key_up")
        term.clear()
        term.setCursorPos(1, 2)
    end)
end

---comment
---@param featureTable table {input = ...,buffer = ...,output = {1 = {...},2={...},...}}
local function configureInputAndOutput(featureTable)
    local outputIndex = 0
    local out = {}
    local feature = {}
    for characteristic, _ in pairs(featureTable) do
        table.insert(feature, characteristic)
    end
    local operations = {
        input = function()
            print("Choose input feature: ")
            local choice = read(nil, feature)
            out["input"] = featureTable[choice]
            return choice
        end,
        buffer = function()
            print("Choose buffer feature: ")
            local choice = read(nil, feature)
            out["buffer"] = featureTable[choice]
            return choice
        end,
        output = function()
            print("Choose output feature: ")
            local choice = read(nil, feature)
            if not out["output"] then
                out["output"] = {}
            end
            print("Need custom name?(y/n)")
            local ans = read(nil, { "y", "n" })
            if string.lower(ans) == "y" then
                local customName = read(nil);
                (out["output"])[customName] = featureTable[choice];
            else
                table.insert(out["output"], featureTable[choice])
            end
            return choice
        end
    }
    while true do
        print("Set input/output/buffer: ")
        local operationsType = read(nil, { "input", "buffer", "output", "exit" })
        if operationsType == "exit" then
            if out["input"] == nil then
                printError("Must have input")
                goto continue
            elseif out["buffer"] == nil then
                printError("Must have buffer")
                goto continue
            elseif out["output"] == nil then
                printError("Must have output")
                goto continue
            end
            break
        end
        if not operations[operationsType] then
            printError("error")
            goto continue
        end
        operations[operationsType]()
        ::continue::
    end
    return out
end

local function saveConfiguredFile(configuredTable)
    local file = io.open("ItemAllocationConfigured.txt", "w+")
    if not file then
        error("can't save configure")
    end
    file:write(textutils.serialise(configuredTable, { allow_repetitions = true }))
    file:close()
end

local function configurationFileExist()
    local file = io.open("ItemAllocationConfigured.txt", "r")
    if file then
        return true
    end
    return false
end

--配置输入输出
local configuredTable
if not configurationFileExist() then
    local featureTable = classifyByFeatures()
    displayClassificationByFeatures(featureTable)
    configuredTable = configureInputAndOutput(featureTable)
    saveConfiguredFile(configuredTable)
    print("Configuration completed, you can remove the items previously used for configuration from the container")
else
    -- 如果已经存在配置文件，调用
    local file = io.open("ItemAllocationConfigured.txt", "r")
    if file then
        file:seek("set")
        configuredTable = textutils.unserialise(file:read("a"))
    end
end


-- 用于识别的物品名称规律：in、leftOut[序号]、rightOut[序号]
for _, chest in ipairs(inventorys) do
    local chestName = peripheral.getName(chest)
    addToChests(getIndex(chest), getChestType(chest), chest)
end

while true do
    local inputChest = table.unpack(chests.input)
    local bufferChest = table.unpack(chests.buffer)
    if not isEmpty(inputChest) then
        waitForReady(inputChest)
        transferToBuffer(inputChest, bufferChest)
        local firstMaterialName, secondMaterialName = getMaterials(bufferChest)
        print(firstMaterialName)
        print(secondMaterialName)
        uniformToTarget(firstMaterialName, bufferChest, chests.left)
        uniformToTarget(secondMaterialName, bufferChest, chests.right)
    end
    sleep(2)
end
