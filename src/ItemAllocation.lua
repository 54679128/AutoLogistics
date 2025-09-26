local inventorys = table.pack(peripheral.find("inventory"))
local chests = { input = {}, left = {}, right = {}, buffer = {} }
local Buffer = require("buffer")

local function getLength(aTable)
    local i = 0
    for _, _ in pairs(aTable) do
        i = i + 1
    end
    return i
end

---接收一个或一组外设名，判断这些外设（只能是通用流体外设或通用物品外设）是否都为空
---@param peripheralNames string|table<number,string>
---@return boolean
local function isEmpty(peripheralNames)
    if type(peripheralNames) == "table" then
        for _, peripheralName in pairs(peripheralNames) do
            local unknowStorge = peripheral.wrap(peripheralName)
            if not unknowStorge then
                error(peripheralName .. "doesn't exsits")
            end
            if unknowStorge.tanks then
                local fluidTanks = unknowStorge.tanks()
                for _, fluidInfo in pairs(fluidTanks) do
                    if fluidInfo then
                        return false
                    end
                end
            end
            if unknowStorge.list then
                local itemList = unknowStorge.list()
                for _, itemInfo in pairs(itemList) do
                    if itemInfo then
                        return false
                    end
                end
            end
        end
        return true
    end
    if type(peripheralNames) == "string" then
        local itemList = peripheral.wrap(peripheralNames).list()
        for _, itemInfo in pairs(itemList) do
            if itemInfo then
                return false
            end
        end
        print("ture")
        return true
    end
    error("perppheralName is't a string or table", 2)
end

local function getMaterials(chest)
    local list = chest.list()
    local firstMaterName
    local firstMaterSlot
    local secondMaterName
    local secondMaterSlot

    for slot, item in pairs(list) do
        if firstMaterName == nil then
            firstMaterName = item.name
            firstMaterSlot = slot
        elseif firstMaterName and secondMaterName == nil and item.name ~= firstMaterName then
            secondMaterName = item.name
            secondMaterSlot = slot
            break
        end
    end
    return firstMaterName, secondMaterName
end

---从缓存向一系列目标容器均匀转移物品
---@param name string
---@param buffer a54679128.Buffer
---@param target table{ccTweaked.peripherals.Inventory,...}
local function uniformToTarget(name, buffer, target)
    local itemTotalCount = 0
    local itemList = buffer:list()
    for slot, item in pairs(itemList) do
        if item.name ~= name then
            goto continue
        end
        itemTotalCount = itemTotalCount + item.count
        ::continue::
    end
    --计算每个容器应得到的原料数量
    local portion = itemTotalCount / getLength(target)
    for _, p in pairs(target) do
        buffer:output(peripheral.getName(p), name, portion)
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
---@alias ConTable { input: string, buffer: string, output: table }
local configuredTable
if not configurationFileExist() then
    local featureTable = classifyByFeatures()
    displayClassificationByFeatures(featureTable)
    ---@cast configuredTable ConTable
    configuredTable = configureInputAndOutput(featureTable)
    saveConfiguredFile(configuredTable)
    print("Configuration completed, you can remove the items previously used for configuration from the container")
else
    -- 如果已经存在配置文件，调用
    local file = io.open("ItemAllocationConfigured.txt", "r")
    if file then
        file:seek("set")
        ---@cast configuredTable ConTable
        configuredTable = textutils.unserialise(file:read("a"))
    end
end

while true do
    if not configuredTable then
        error("unknown error")
    end
    ---@cast configuredTable ConTable
    local inputContainer = peripheral.wrap(configuredTable.input[1])
    ---@diagnostic disable-next-line: param-type-mismatch
    local bufferContainer = Buffer:asBuffer(peripheral.wrap(configuredTable.buffer[1]))
    if not isEmpty(configuredTable.input) then
        waitForReady(inputContainer)
        bufferContainer:input(configuredTable.input[1])
        local firstMaterialName, secondMaterialName = getMaterials(bufferContainer.inventory)
        print(firstMaterialName)
        print(secondMaterialName)
        local tempFirst = {}
        local tempSecond = {}
        for _, name in pairs(configuredTable.output[1]) do
            table.insert(tempFirst, peripheral.wrap(name))
        end
        for _, name in pairs(configuredTable.output[2]) do
            table.insert(tempSecond, peripheral.wrap(name))
        end
        uniformToTarget(firstMaterialName, bufferContainer, tempFirst)
        uniformToTarget(secondMaterialName, bufferContainer, tempSecond)
    end
    sleep(2)
end
