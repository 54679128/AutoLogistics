local inventorys = table.pack(peripheral.find("inventory"))
local chests = { input = {}, left = {}, right = {}, buffer = {} }

local function getLength(aTable)
    local i = 0
    for _, _ in pairs(aTable) do
        i = i + 1
    end
    return i
end
local function isLeftChest(chest)
    return string.find(chest.getItemDetail(1).displayName, "left")
end
local function isRightChest(chest)
    return string.find(chest.getItemDetail(1).displayName, "right")
end
local function isInChest(chest)
    return string.find(chest.getItemDetail(1).displayName, "in")
end
local function isBufferChest(chest)
    return string.find(chest.getItemDetail(1).displayName, "buffer")
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

-- 用于识别的物品名称规律：in、leftOut[序号]、rightOut[序号]
for _, chest in ipairs(inventorys) do
    local chestName = peripheral.getName(chest)
    --local customName = chest.getItemDetail(1).displayName
    --print("customName: " .. customName)
    --print("getIndex: " .. tostring(getIndex(chest)) .. " ,getChestType: " .. getChestType(chest))
    --print(" ")
    addToChests(getIndex(chest), getChestType(chest), chest)
    --sleep(0.5)
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

local function uniformToLeft(name, buffer)
    --可能有些出口暂时被堵塞了
    local tryChests = {}
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

    local portion = itemTotalCount / getLength(chests.left)
    for _, leftChest in pairs(chests.left) do
        local willTransfer = portion
        local notTransfer = 0
        for _, slot in ipairs(itemSlots) do
            notTransfer = notTransfer + leftChest.pullItems(peripheral.getName(buffer), slot, willTransfer - notTransfer)
            if notTransfer == willTransfer then
                break
            end
        end
        if notTransfer ~= willTransfer then
            table.insert(tryChests, leftChest)
        end
    end
    --有奇怪的butterfly
    --[[
    for _, tryChest in pairs(tryChests) do
        local willTransfer = portion
        local notTransfer = 0
        local fgla = true
        while fgla do
            for _, slot in ipairs(itemSlots) do
                notTransfer = notTransfer +
                    tryChest.pullItems(peripheral.getName(buffer), slot, willTransfer - notTransfer)
                if notTransfer == willTransfer then
                    fgla = false
                    break
                end
            end
        end
    end
    --]]
end

local function uniformToRight(name, buffer)
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
    local portion = itemTotalCount / getLength(chests.right)
    for _, rightChest in pairs(chests.right) do
        local willTransfer = portion
        local notTransfer = 0
        for _, slot in ipairs(itemSlots) do
            notTransfer = notTransfer +
                rightChest.pullItems(peripheral.getName(buffer), slot, willTransfer - notTransfer)
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

while true do
    local inputChest = table.unpack(chests.input)
    local bufferChest = table.unpack(chests.buffer)
    if not isEmpty(inputChest) then
        waitForReady(inputChest)
        transferToBuffer(inputChest, bufferChest)
        local firstMaterialName, secondMaterialName = getMaterials(bufferChest)
        print(firstMaterialName)
        print(secondMaterialName)
        uniformToLeft(firstMaterialName, bufferChest)
        uniformToRight(secondMaterialName, bufferChest)
    end
    sleep(2)
end
